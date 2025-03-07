import router from '@ohos.router';
import hilog from '@ohos.hilog';
import promptAction from '@ohos.promptAction';
import { BookingConstants } from '../constants/BookingConstants';
import { AccountBookModel } from '../model/AccountBookModel';
import { BookDBHelper } from '../database/BookDBHelper';
import { CustomAlertDialog } from '../components/CustomDialog';

/**
 * 路由参数接口
 */
export interface RouteParam {
  accountId?: number;
}

@Entry
@Component
struct AccountBookListPage {
  @State accountBooks: AccountBookModel[] = [];
  @State isLoading: boolean = true;
  private dbHelper: BookDBHelper = BookDBHelper.getInstance();
  private currentAccountId: number = 0;

  // 删除确认对话框控制器
  private deleteDialogController: CustomDialogController = new CustomDialogController({
    builder: CustomAlertDialog({
      title: '确认删除',
      message: '确定要删除这个账本吗？',
      cancelText: '取消',
      confirmText: '删除',
      onCancel: () => {
        hilog.info(0x0000, 'AccountBookListPage', '取消删除账本');
      },
      onConfirm: async () => {
        if (this.currentAccountId) {
          await this.deleteAccountBook(this.currentAccountId);
        }
      }
    }),
    alignment: DialogAlignment.Center,
    autoCancel: true,
    customStyle: true
  });
  
  aboutToAppear() {
    this.loadAccountBooks();
  }
  
  async loadAccountBooks() {
    try {
      this.isLoading = true;
      this.accountBooks = await this.dbHelper.getAllAccountBooks();
    } catch (err) {
      hilog.error(0x0000, 'AccountBookListPage', 'Load account books failed: %{private}s', JSON.stringify(err));
      promptAction.showToast({
        message: '加载账本失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }
  
  async setDefaultAccountBook(accountId: number) {
    try {
      const result = await this.dbHelper.setDefaultAccountBook(accountId);
      if (result) {
        promptAction.showToast({
          message: '设置默认账本成功',
          duration: 2000
        });
        this.loadAccountBooks();
      }
    } catch (err) {
      hilog.error(0x0000, 'AccountBookListPage', 'Set default account book failed: %{private}s', JSON.stringify(err));
      promptAction.showToast({
        message: '设置默认账本失败',
        duration: 2000
      });
    }
  }
  
  async confirmDeleteAccountBook(accountId: number) {
    try {
      const accountBook = this.accountBooks.find(ab => ab.id === accountId);
      if (!accountBook) {
        return;
      }
      
      if (accountBook.isDefault === BookingConstants.ACCOUNT_IS_DEFAULT) {
        promptAction.showToast({
          message: '默认账本不能删除',
          duration: 2000
        });
        return;
      }
      
      // 设置当前要删除的账本ID和名称
      this.currentAccountId = accountId;

      // 更新对话框消息
      this.deleteDialogController.close();
      this.deleteDialogController = new CustomDialogController({
        builder: CustomAlertDialog({
          title: '确认删除',
          message: `确定要删除账本「${accountBook.name}」吗？`,
          cancelText: '取消',
          confirmText: '删除',
          onCancel: () => {
            hilog.info(0x0000, 'AccountBookListPage', '取消删除账本');
          },
          onConfirm: async () => {
            if (this.currentAccountId) {
              await this.deleteAccountBook(this.currentAccountId);
            }
          }
        }),
        alignment: DialogAlignment.Center,
        autoCancel: true,
        customStyle: true
      });
      
      // 显示删除确认对话框
      this.deleteDialogController.open();
    } catch (err) {
      hilog.error(0x0000, 'AccountBookListPage', 'Confirm delete account book failed: %{private}s', JSON.stringify(err));
    }
  }
  
  async deleteAccountBook(accountId: number) {
    try {
      const deleteResult = await this.dbHelper.deleteAccountBook(accountId);
      if (deleteResult) {
        promptAction.showToast({
          message: '删除账本成功',
          duration: 2000
        });
        this.loadAccountBooks();
      } else {
        promptAction.showToast({
          message: '删除账本失败',
          duration: 2000
        });
      }
    } catch (err) {
      hilog.error(0x0000, 'AccountBookListPage', 'Delete account book failed: %{private}s', JSON.stringify(err));
      promptAction.showToast({
        message: '删除账本失败',
        duration: 2000
      });
    }
  }
  
  private navigateToEdit(accountBookId?: number): void {
    router.pushUrl({
      url: BookingConstants.ACCOUNT_BOOK_EDIT_ROUTE,
      params: { accountId: accountBookId }
    });
  }
  
  private selectAccountBook(accountBook: AccountBookModel): void {
    // 返回选中的账本
    router.back({
      url: 'pages/HomePage',
      params: {
        selectedAccountId: accountBook.id
      }
    });
  }
  
  build() {
    Column() {
      Row()
        .height(20)
      // 顶部导航栏
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .margin({ left: 16 })
          .onClick(() => {
            router.back();
          })
        
        Text('账本管理')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(50)
      .padding({ left: 10, right: 10 })

      // 账本列表
      if (this.isLoading) {
        LoadingComponent()
      } else if (this.accountBooks.length === 0) {
        EmptyComponent({
          onAddAccount: () => this.navigateToEdit()
        })
      } else {
        List() {
          ForEach(this.accountBooks, (item: AccountBookModel) => {
            ListItem() {
              Row() {
                Image(item.icon)
                  .width(40)
                  .height(40)
                  .margin({ right: 12 })
                
                Column() {
                  Text(item.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                  Text(`余额：${item.balance.toFixed(2)}`)
                    .fontSize(14)
                    .fontColor('#666666')
                    .margin({ top: 4 })
                  
                  if (item.isDefault === BookingConstants.ACCOUNT_IS_DEFAULT) {
                    Text('默认账本')
                      .fontSize(12)
                      .fontColor('#4CAF50')
                      .margin({ top: 4 })
                  }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                
                if (item.isDefault !== BookingConstants.ACCOUNT_IS_DEFAULT) {
                  Row() {
                    Button({ type: ButtonType.Normal }) {
                      Text('设为默认')
                        .fontSize(14)
                        .fontColor('#4CAF50')
                    }
                    .height(32)
                    .backgroundColor('rgba(76, 175, 80, 0.1)')
                    .borderRadius(16)
                    .margin({ right: 8 })
                    .onClick(() => this.setDefaultAccountBook(item.id || 0))
                    
                    Image($r('app.media.ic_edit_cartoon_new'))
                      .width(24)
                      .height(24)
                      .margin({ right: 16 })
                      .onClick(() => this.navigateToEdit(item.id))
                    
                    Image($r('app.media.ic_delete_cartoon_new'))
                      .width(24)
                      .height(24)
                      .onClick(() => this.confirmDeleteAccountBook(item.id || 0))
                  }
                } else {
                  Image($r('app.media.ic_edit_cartoon_new'))
                    .width(24)
                    .height(24)
                    .onClick(() => this.navigateToEdit(item.id))
                }
              }
              .width('100%')
              .padding(16)
              .backgroundColor($r('app.color.BG_INCOME_COLOR'))
              .borderRadius(8)
              .onClick(() => this.selectAccountBook(item))
            }
            .margin({ bottom: 10 })
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
      }
      
      Button('添加账本')
        .width('90%')
        .height(50)
        .backgroundColor('#4CAF50')
        .borderRadius(25)
        .fontSize(16)
        .fontColor(Color.White)
        .margin({ top: 20, bottom: 20 })
        .onClick(() => {
          this.navigateToEdit();
        })

      Row()
        .height(15)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

@Component
struct LoadingComponent {
  build() {
    Column() {
      LoadingProgress()
        .width(50)
        .height(50)
      
      Text('加载中...')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}

@Component
struct EmptyComponent {
  onAddAccount?: () => void = () => {};
  
  build() {
    Column() {
      Image($r('app.media.ic_default_cartoon_new'))
        .width(100)
        .height(100)
        .opacity(0.6)
      
      Text('暂无账本数据')
        .fontSize(16)
        .fontColor('#666666')
        .margin({ top: 10 })
      
      Button('添加账本')
        .width(150)
        .height(40)
        .backgroundColor('#4CAF50')
        .borderRadius(20)
        .fontSize(16)
        .fontColor(Color.White)
        .margin({ top: 20 })
        .onClick(() => {
          if (this.onAddAccount) {
            this.onAddAccount();
          }
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
