import prompt from '@ohos.promptAction';
import { BookingConstants } from '../constants/BookingConstants';
import { DateUtils } from '../utils/DateUtils';
import { CategoryModel } from '../model/CategoryModel';
import { RecordModel } from '../model/RecordModel';
import { RecordWithCategory } from '../model/RecordWithCategory';
import { CustomAlertDialog, EditRecordDialog } from '../components/CustomDialog';
import { CategoryDBHelper } from '../database/CategoryDBHelper';
import { RecordDBHelper } from '../database/RecordDBHelper';
import { BookDBHelper } from '../database/BookDBHelper';
import { IconUtils } from '../utils/IconUtils';
import { AccountBookModel } from '../model/AccountBookModel';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
export default struct AccountBook {
  @State records: RecordWithCategory[] = [];
  @State income: number = 0;
  @State expense: number = 0;
  @State balance: number = 0;
  @State currentMonth: string = DateUtils.getCurrentMonthStr();
  @State categories: CategoryModel[] = [];
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @State accountBooks: AccountBookModel[] = [];
  @State selectedAccountId: number = 0;
  @State selectedAccountName: string = '';
  @State showAccountSelector: boolean = false;
  
  // 编辑弹窗相关状态
  @State editAmount: string = '';
  @State editDescription: string = '';
  @State editDate: Date = new Date();
  @State editDialogShow: boolean = false;
  @State selectedCategoryId: number = 0;
  @State recordType: number = BookingConstants.RECORD_TYPE_EXPENSE;
  @State currentRecord: RecordWithCategory = new RecordWithCategory(new RecordModel(0, 0, 0, '', 0, 0),
    new CategoryModel(BookingConstants.EXPENSE_TYPE, "", IconUtils.getResourceByKey(BookingConstants.ICON_MISC)));

  // 自定义对话框控制器
  private deleteDialogController: CustomDialogController = new CustomDialogController({
    builder: CustomAlertDialog({
      title: '确认删除',
      message: '确定要删除这条记录吗？',
      cancelText: '取消',
      confirmText: '删除',
      onCancel: () => {
        console.info('取消删除');
      },
      onConfirm: async () => {
        if (this.currentRecord && this.currentRecord.id) {
          await this.deleteRecord(this.currentRecord);
        }
      }
    }),
    alignment: DialogAlignment.Center,
    autoCancel: true,
    customStyle: true
  });

  // 编辑对话框控制器
  private editDialogController: CustomDialogController = new CustomDialogController({
    builder: EditRecordDialog({
      editAmount: this.editAmount,
      editDescription: this.editDescription,
      selectedCategoryId: this.selectedCategoryId,
      recordType: this.recordType,
      onConfirm: () => {
        this.saveEditedRecord();
      },
      onCancel: () => {
        console.info('取消编辑');
      }
    }),
    alignment: DialogAlignment.Center,
    autoCancel: true,
    customStyle: true
  });

  private bookDBHelper: BookDBHelper = BookDBHelper.getInstance();

  async aboutToAppear() {
    await this.loadAccountBooks();
  }

  async loadAccountBooks() {
    try {
      // 初始化账本数据库
      await this.bookDBHelper.initDatabase();
      
      // 加载账本列表
      this.accountBooks = await this.bookDBHelper.getAllAccountBooks();
      
      if (this.accountBooks.length > 0) {
        // 默认选择第一个账本
        const defaultAccount = this.accountBooks.find(account => account.isDefault === BookingConstants.ACCOUNT_IS_DEFAULT);
        if (defaultAccount && defaultAccount.id !== undefined) {
          this.selectedAccountId = defaultAccount.id;
          this.selectedAccountName = defaultAccount.name;
        } else if (this.accountBooks[0].id !== undefined) {
          this.selectedAccountId = this.accountBooks[0].id;
          this.selectedAccountName = this.accountBooks[0].name;
        }
      }
      
      // 加载记录列表
      await this.loadData();
    } catch (error) {
      console.error('加载账本失败:', JSON.stringify(error));
    }
  }
  
  onPageShow() {
    // 页面每次显示时重新加载数据，确保数据实时更新
    this.loadAccountBooks();
  }

  // 控制返回按钮行为
  onBackPress() {
    // 不允许返回到加载页
    return true;
  }

  async loadData() {
    try {
      // 加载记录列表
      this.records = await RecordDBHelper.getInstance().getRecordsWithCategory(this.selectedAccountId);
      
      // 统计收支情况
      this.calculateSummary();
      
      // 加载分类列表
      this.categories = await CategoryDBHelper.getInstance().getAllCategories();
    } catch (error) {
      console.error('loadData error:', error);
      prompt.showToast({
        message: '加载数据失败',
        duration: 2000
      });
    }
  }

  calculateSummary() {
    this.income = 0;
    this.expense = 0;
    
    this.records.forEach(record => {
      if (record.type === BookingConstants.RECORD_TYPE_INCOME) {
        this.income += record.amount;
      } else {
        this.expense += record.amount;
      }
    });
    
    this.balance = this.income - this.expense;
  }

  async deleteRecord(record: RecordWithCategory) {
    try {
      if (record.id) {
        await RecordDBHelper.getInstance().deleteRecord(record.id);
      }
      prompt.showToast({
        message: '删除成功',
        duration: 2000
      });
      await this.loadData();
    } catch (error) {
      console.error('deleteRecord error:', error);
      prompt.showToast({
        message: '删除失败',
        duration: 2000
      });
    }
  }

  showEditDialog(record: RecordWithCategory) {
    this.currentRecord = record;
    this.editAmount = record.amount.toString();
    this.editDescription = record.description || '';
    this.editDate = new Date(record.recordTime);
    this.selectedCategoryId = record.categoryId;
    this.recordType = record.type;
    
    this.editDialogController.open();
  }

  async saveEditedRecord() {
    try {
      if (!this.editAmount || parseFloat(this.editAmount) <= 0) {
        prompt.showToast({
          message: '请输入有效金额',
          duration: 2000
        });
        return;
      }

      if (this.selectedCategoryId === 0) {
        prompt.showToast({
          message: '请选择分类',
          duration: 2000
        });
        return;
      }

      // 创建更新后的记录对象
      const updatedRecord: RecordModel = new RecordModel(
        this.recordType,
        this.selectedCategoryId,
        parseFloat(this.editAmount),
        this.editDescription,
        this.editDate.getTime(),
        this.selectedAccountId,
        Date.now(),
        this.currentRecord.id
      );

      const result = await RecordDBHelper.getInstance().updateRecord(updatedRecord);
      if (result > 0) {
        this.editDialogController.close();
        prompt.showToast({
          message: '更新成功',
          duration: 2000
        });
        await this.loadData();
      } else {
        prompt.showToast({
          message: '更新失败',
          duration: 2000
        });
      }
    } catch (error) {
      hilog.error(0x0000, 'AccountBook', 'saveEditedRecord error: %{private}s', JSON.stringify(error));
      prompt.showToast({
        message: '更新失败',
        duration: 2000
      });
    }
  }

  @Builder itemEnd(record: RecordWithCategory) {
    Row() {
      Column() {
        Image($r('app.media.ic_edit_cartoon_new'))
          .width(28)
          .height(28)
        Text('编辑')
          .fontSize(12)
          .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
      }
      .backgroundColor($r('app.color.BG_COLOR_SECONDARY'))
      .borderRadius(12)
      .width(56)
      .height(60)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.showEditDialog(record);
      })

      Column() {
        Image($r('app.media.ic_delete_cartoon_new'))
          .width(28)
          .height(28)
        Text('删除')
          .fontSize(12)
          .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
      }
      .width(56)
      .height(60)
      .borderRadius(12)
      .backgroundColor($r('app.color.BG_COLOR_SECONDARY'))
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        // 设置当前记录
        this.currentRecord = record;
        // 显示删除确认对话框
        this.deleteDialogController.open();
      })
    }
    .width(120)
    .height(200)
    .justifyContent(FlexAlign.SpaceEvenly)
    .margin({bottom: 8})
  }

  // 显示账本选择器
  showAccountBookSelector() {
    this.showAccountSelector = true;
  }
  
  // 选择账本
  selectAccountBook(accountId: number, accountName: string) {
    this.selectedAccountId = accountId;
    this.selectedAccountName = accountName;
    this.showAccountSelector = false;
    this.loadData();
  }

  build() {
    Column() {
      Row()
        .height(20)
      // 顶部导航栏
      Row() {
        Row() {
          Text(this.selectedAccountName || this.currentMonth)
            .fontSize(20)
            .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
            .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
          
          if (this.accountBooks.length > 0) {
            Image($r('app.media.ic_left_cartoon_new'))
              .width(24)
              .height(24)
              .margin({ left: 4 })
          }
        }
        .onClick(() => {
          this.showAccountBookSelector();
        })
      }
      .width('100%')
      .height(50)
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.Center)

      // 收支概览卡片
      Row() {
        Column() {
          Text($r('app.string.income'))
            .fontSize(14)
            .fontColor($r('app.color.TEXT_SECONDARY_COLOR'))
            .margin({ bottom: 4 })
          Text(`¥${this.income.toFixed(2)}`)
            .fontSize(20)
            .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
            .fontColor($r('app.color.TEXT_INCOME_COLOR'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Divider()
          .vertical(true)
          .height(40)
          .color($r('sys.color.ohos_id_color_list_separator'))

        Column() {
          Text($r('app.string.expense'))
            .fontSize(14)
            .fontColor($r('app.color.TEXT_SECONDARY_COLOR'))
            .margin({ bottom: 4 })
          Text(`¥${this.expense.toFixed(2)}`)
            .fontSize(20)
            .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
            .fontColor($r('app.color.TEXT_EXPENSE_COLOR'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Divider()
          .vertical(true)
          .height(40)
          .color($r('sys.color.ohos_id_color_list_separator'))

        Column() {
          Text($r('app.string.balance'))
            .fontSize(14)
            .fontColor($r('app.color.TEXT_SECONDARY_COLOR'))
            .margin({ bottom: 4 })
          Text(`¥${this.balance.toFixed(2)}`)
            .fontSize(20)
            .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
            .fontColor(this.balance >= 0 ? $r('app.color.TEXT_INCOME_COLOR') : $r('app.color.TEXT_EXPENSE_COLOR'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.BG_COLOR'))
      .borderRadius(10)
      .margin({ top: 10, bottom: 10, left: 16, right: 16 })

      // 记录列表
      List() {
        if (this.records.length === 0) {
          ListItem() {
            Column() {
              Image($r(BookingConstants.EMPTY_ICON))
                .width(100)
                .height(100)
                .margin({ bottom: 20 })
              Text($r('app.string.no_records'))
                .fontSize(16)
                .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
            }
            .width('100%')
            .height(200)
            .justifyContent(FlexAlign.Center)
          }
        } else {
          ForEach(this.records, (record: RecordWithCategory) => {
            ListItem() {
              Row() {
                Image(record.icon)
                  .width(40)
                  .height(40)
                  .margin({ right: 10 })
                  .objectFit(ImageFit.Contain)

                Column() {
                  Row() {
                    Text(record.name)
                      .fontSize(16)
                      .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
                    // 添加分类标签
                    if (record.category && record.category.name) {
                      Text(record.category.name)
                        .fontSize(12)
                        .fontColor($r('app.color.BG_COLOR'))
                        .backgroundColor(record.type === BookingConstants.RECORD_TYPE_INCOME ?
                        $r('app.color.TEXT_INCOME_COLOR') : $r('app.color.TEXT_EXPENSE_COLOR'))
                        .borderRadius(4)
                        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                        .margin({ left: 8 })
                    }
                    Blank()
                    Text(record.type === BookingConstants.RECORD_TYPE_INCOME ? '+' : '-')
                      .fontSize(16)
                      .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
                      .fontColor(record.type === BookingConstants.RECORD_TYPE_INCOME ?
                      $r('app.color.TEXT_INCOME_COLOR') : $r('app.color.TEXT_EXPENSE_COLOR'))
                    Text(`${record.amount.toFixed(2)}`)
                      .fontSize(16)
                      .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
                      .fontColor(record.type === BookingConstants.RECORD_TYPE_INCOME ?
                      $r('app.color.TEXT_INCOME_COLOR') : $r('app.color.TEXT_EXPENSE_COLOR'))
                  }
                  .width('100%')

                  Row() {
                    Text(record.description || '')
                      .fontSize(14)
                      .fontColor($r('app.color.TEXT_SECONDARY_COLOR'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Blank()
                    Text(DateUtils.formatDate(record.recordTime))
                      .fontSize(14)
                      .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
                  }
                  .width('100%')
                  .margin({ top: 4 })
                }
                .layoutWeight(1)
              }
              .width('100%')
              .padding({ top: 12, bottom: 12, left: 16, right: 16})
              .backgroundColor(record.type === BookingConstants.RECORD_TYPE_INCOME ?
              $r('app.color.BG_INCOME_COLOR') : $r('app.color.BG_EXPENSE_COLOR'))
              .borderRadius(8)
              .border({
                width: 1,
                color: record.type === BookingConstants.RECORD_TYPE_INCOME ?
                $r('app.color.BORDER_INCOME_COLOR') : $r('app.color.BORDER_EXPENSE_COLOR'),
                style: BorderStyle.Solid
              })
              .margin({ bottom: 6 })
            }
            .margin({right: this.currentBreakpoint === 'sm' ? 0 : 16})
            .swipeAction({
              end: {
                builder: this.itemEnd(record),
                onAction: () => {
                  // 删除该操作，使用按钮点击触发相应功能
                },
                actionAreaDistance: 120
              }
            })
          })
        }
      }
      .layoutWeight(1)
      .padding({ left: 16, right: 16 })
      .lanes(this.currentBreakpoint === 'sm' ? 1 : 2)

      // 账本选择器
      if (this.showAccountSelector) {
        Column() {
          // 遮罩层
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#88000000')
            .position({ x: 0, y: 0 })
            .onClick(() => {
              this.showAccountSelector = false;
            })

          // 选择器内容
          Column() {
            // 标题栏
            Row() {
              Text('选择账本')
                .fontSize(18)
                .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
                .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ top: 16, bottom: 16 })

            // 账本列表
            List() {
              ForEach(this.accountBooks, (account: AccountBookModel) => {
                ListItem() {
                  Row() {
                    Image(account.icon)
                      .width(32)
                      .height(32)
                      .margin({ right: 16 })

                    Text(account.name)
                      .fontSize(16)
                      .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
                      .layoutWeight(1)

                    if (account.id === this.selectedAccountId) {
                      Image($r('app.media.ic_misc_cartoon_new'))
                        .width(24)
                        .height(24)
                    }
                  }
                  .width('100%')
                  .padding(16)
                  .onClick(() => {
                    if (account.id !== undefined) {
                      this.selectAccountBook(account.id, account.name);
                    }
                  })
                }
              })
            }
            .divider({
              strokeWidth: 1,
              color: $r('app.color.BORDER_COLOR'),
              startMargin: 16,
              endMargin: 16
            })
            .layoutWeight(1)
          }
          .width('100%')
          .height('50%')
          .backgroundColor($r('app.color.BG_COLOR'))
          .borderRadius({ topLeft: 16, topRight: 16 })
          .position({ x: 0, y: '50%' })
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
      }

      Row()
        .height(15)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.BG_COLOR'))
  }
}
