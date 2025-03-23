import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import hilog from '@ohos.hilog';
import { BookDBHelper } from '../database/BookDBHelper';
import { BookingConstants } from '../constants/BookingConstants';
import { AccountBookModel } from '../model/AccountBookModel';
import { RouteParam } from './AccountBookListPage';
import { IconUtils } from '../utils/IconUtils';

interface AccountTypeItem {
  type: number;
  name: string;
  icon: Resource;
}

@Entry
@Component
struct AccountBookEditPage {
  @State accountBook: AccountBookModel = new AccountBookModel('', 0, 0, IconUtils.getResourceByKey(""));
  @State isNewAccount: boolean = true;
  @State isLoading: boolean = false;
  @State accountTypes: Array<AccountTypeItem> = [
    { type: BookingConstants.ACCOUNT_TYPE_CASH, name: '现金', icon: $r('app.media.ic_cash') },
    { type: BookingConstants.ACCOUNT_TYPE_BANK_CARD, name: '银行卡', icon: $r('app.media.ic_bank') },
    { type: BookingConstants.ACCOUNT_TYPE_ALIPAY, name: '支付宝', icon: $r('app.media.ic_alipay') },
    { type: BookingConstants.ACCOUNT_TYPE_WECHAT, name: '微信', icon: $r('app.media.ic_wechat') },
    { type: BookingConstants.ACCOUNT_TYPE_STOCK, name: '股票', icon: $r('app.media.ic_other_cartoon_new') },
    { type: BookingConstants.ACCOUNT_TYPE_OTHER, name: '其他', icon: $r('app.media.ic_other') }
  ];
  @State selectedType: number = BookingConstants.ACCOUNT_TYPE_CASH;
  private dbHelper: BookDBHelper = BookDBHelper.getInstance();
  
  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as RouteParam;
    const accountId = params?.accountId;
    
    if (accountId) {
      this.isNewAccount = false;
      this.loadAccountBook(accountId);
    } else {
      // 初始化新账本
      this.accountBook = new AccountBookModel(
        '',
        BookingConstants.ACCOUNT_TYPE_CASH,
        0,
        this.accountTypes[0].icon
      );
      this.selectedType = BookingConstants.ACCOUNT_TYPE_CASH;
    }
  }
  
  /**
   * 加载账本信息
   */
  async loadAccountBook(accountId: number) {
    try {
      this.isLoading = true;
      const accountBook = await this.dbHelper.getAccountBookById(accountId);
      if (accountBook) {
        this.accountBook = accountBook;
        this.selectedType = accountBook.type;
      } else {
        promptAction.showToast({
          message: '账本不存在'
        });
        setTimeout(() => router.back(), 2000);
      }
    } catch (err) {
      hilog.error(0x0000, 'AccountBookEditPage', 'Load account book failed: %{private}s', JSON.stringify(err));
      promptAction.showToast({
        message: '加载账本信息失败'
      });
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 保存账本
   */
  async saveAccountBook() {
    // 表单验证
    if (!this.accountBook.name || !this.accountBook.name.trim()) {
      promptAction.showToast({
        message: '请输入账本名称'
      });
      return;
    }
    
    try {
      this.isLoading = true;
      
      // 设置图标
      const iconType = this.accountTypes.find(item => item.type === this.selectedType);
      if (iconType) {
        this.accountBook.icon = iconType.icon;
      }
      
      // 设置类型
      this.accountBook.type = this.selectedType;
      
      let result = false;
      if (this.isNewAccount) {
        // 新增账本
        const rowId = await this.dbHelper.insertAccountBook(this.accountBook);
        result = rowId > 0;
      } else {
        // 更新账本
        result = await this.dbHelper.updateAccountBook(this.accountBook);
      }
      
      if (result) {
        promptAction.showToast({
          message: this.isNewAccount ? '添加账本成功' : '修改账本成功'
        });
        setTimeout(() => router.back(), 1500);
      } else {
        promptAction.showToast({
          message: this.isNewAccount ? '添加账本失败' : '修改账本失败'
        });
      }
    } catch (err) {
      hilog.error(0x0000, 'AccountBookEditPage', 'Save account book failed: %{private}s', JSON.stringify(err));
      promptAction.showToast({
        message: this.isNewAccount ? '添加账本失败' : '修改账本失败'
      });
    } finally {
      this.isLoading = false;
    }
  }
  
  build() {
    Column() {
      Row()
        .height(20)
        
      // 标题栏
      TitleBar({ title: this.isNewAccount ? '添加账本' : '编辑账本' })
      
      // 表单内容
      if (this.isLoading) {
        LoadingComponent()
      } else {
        Column() {
          // 名称输入
          Row() {
            Text('账本名称')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .width('30%')

            Text('*')
              .fontSize(16)
              .fontColor(Color.Red)
              .margin({ left: 4 })

            TextInput({ text: this.accountBook.name })
              .height(50)
              .width('65%')
              .backgroundColor($r('app.color.BG_COLOR_SECONDARY'))
              .border({
                width: 1,
                color: $r('app.color.BORDER_COLOR'),
                radius: 8
              })
              .padding({ left: 8, right: 8 })
              .onChange((value: string): void => {
                this.accountBook.name = value;
              })
          }
          .width('90%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .padding({ top: 12, bottom: 12 })

          // 账本类型选择
          Column() {
            Row() {
              Text('账本类型')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)

              Text('*')
                .fontSize(16)
                .fontColor(Color.Red)
                .margin({ left: 4 })
            }
            .width('90%')
            .alignItems(VerticalAlign.Center)
            .margin({ bottom: 8, left: 8 })

            Grid() {
              ForEach(this.accountTypes, (item: AccountTypeItem) => {
                GridItem() {
                  Column() {
                    Image(item.icon)
                      .width(40)
                      .height(40)

                    Text(item.name)
                      .fontSize(14)
                      .margin({ top: 8 })
                      .fontColor(this.selectedType === item.type ? $r('app.color.TEXT_PRIMARY_COLOR') : $r('app.color.TEXT_SECONDARY_COLOR'))
                  }
                  .width('100%')
                  .height(80)
                  .backgroundColor(this.selectedType === item.type ? $r('app.color.BG_COLOR_SECONDARY') : $r('app.color.BG_COLOR'))
                  .borderRadius(8)
                  .padding(8)
                  .justifyContent(FlexAlign.Center)
                  .onClick((): void => {
                    this.selectedType = item.type;
                  })
                }
              })
            }
            .columnsTemplate('1fr 1fr 1fr')
            .rowsGap(10)
            .columnsGap(10)
            .width('90%')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .height('50%')
          .margin({ bottom: 16 })

          // 初始余额输入
          if (this.isNewAccount) {
            Row() {
              Text('初始余额')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .width('30%')

              TextInput({ text: this.accountBook.balance.toString() })
                .height(50)
                .width('65%')
                .backgroundColor($r('app.color.BG_COLOR'))
                .padding({ left: 8, right: 8 })
                .type(InputType.Number)
                .onChange((value: string): void => {
                  this.accountBook.balance = parseFloat(value) || 0;
                })
            }
            .width('90%')
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)
            .padding({ top: 12, bottom: 12 })
          }

          // 提交按钮
          Button('保存')
            .width('50%')
            .height(50)
            .backgroundColor($r('app.color.SUCCESS_COLOR'))
            .fontColor(Color.White)
            .borderRadius(8)
            .margin({ top: 40, bottom: 20 })
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .onClick(() => this.saveAccountBook())
        }
        .width('100%')
        .height('100%')
        .padding(16)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.BG_COLOR'))
  }
}

@Component
struct TitleBar {
  title: string = '账本管理';
  
  build() {
    Row() {
      Button({ type: ButtonType.Normal }) {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
      }
      .backgroundColor(Color.Transparent)
      .width(36)
      .height(36)
      .onClick(() => router.back())
      
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      
      Blank()
        .width(36)
    }
    .width('100%')
    .height(50)
    .padding({ left: 10, right: 10 })
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
        .fontColor('#666')
        .margin({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
