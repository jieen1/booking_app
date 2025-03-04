import { router } from '@kit.ArkUI';
import prompt from '@ohos.promptAction';
import { BookingConstants } from '../constants/BookingConstants';
import { DateUtils } from '../utils/DateUtils';
import { DBHelper } from '../database/DBHelper';
import { CategoryModel } from '../model/CategoryModel';
import { RecordModel } from '../model/RecordModel';
import { RecordWithCategory } from '../model/RecordWithCategory';
import { CustomAlertDialog, EditRecordDialog } from '../components/CustomDialog';

@Entry
@Component
struct AccountBook {
  @State records: RecordWithCategory[] = [];
  @State income: number = 0;
  @State expense: number = 0;
  @State balance: number = 0;
  @State currentMonth: string = DateUtils.getCurrentMonthStr();
  @State categories: CategoryModel[] = [];
  
  // 编辑弹窗相关状态
  @State editAmount: string = '';
  @State editDescription: string = '';
  @State editDate: Date = new Date();
  @State editDialogShow: boolean = false;
  @State selectedCategoryId: number = 0;
  @State recordType: number = BookingConstants.RECORD_TYPE_EXPENSE;
  @State currentRecord: RecordWithCategory = new RecordWithCategory(new RecordModel(0, 0, 0, '', 0, 0),
    new CategoryModel(BookingConstants.EXPENSE_TYPE, "", DBHelper.getInstance().getResourceByKey(BookingConstants.ICON_MISC)));

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

  async aboutToAppear() {
    await this.loadData();
  }

  onPageShow() {
    // 页面每次显示时重新加载数据，确保数据实时更新
    this.loadData();
  }

  // 控制返回按钮行为
  onBackPress() {
    // 不允许返回到加载页
    return true;
  }

  async loadData() {
    try {
      // 加载记录列表
      this.records = await DBHelper.getInstance().getRecordsWithCategory();
      
      // 统计收支情况
      this.calculateSummary();
      
      // 加载分类列表
      this.categories = await DBHelper.getInstance().getAllCategories();
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

  goToAddRecord() {
    router.pushUrl({
      url: BookingConstants.ADD_RECORD_ROUTE
    });
  }

  goToStatistics() {
    router.pushUrl({
      url: BookingConstants.STATISTICS_ROUTE
    });
  }

  async deleteRecord(record: RecordWithCategory) {
    try {
      if (record.id) {
        await DBHelper.getInstance().deleteRecord(record.id);
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

      const updatedRecord: RecordModel = new RecordModel(
        this.recordType,
        this.selectedCategoryId,
        parseFloat(this.editAmount),
        this.editDescription,
        this.editDate.getTime(),
        this.currentRecord.id,
      );

      await DBHelper.getInstance().updateRecord(updatedRecord);
      this.editDialogController.close();
      prompt.showToast({
        message: '更新成功',
        duration: 2000
      });
      await this.loadData();
    } catch (error) {
      console.error('saveEditedRecord error:', error);
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
          .fontColor(BookingConstants.TEXT_SECONDARY_COLOR)
      }
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
          .fontColor(BookingConstants.TEXT_SECONDARY_COLOR)
      }
      .width(56)
      .height(60)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        // 设置当前记录
        this.currentRecord = record;
        // 显示删除确认对话框
        this.deleteDialogController.open();
      })
    }
    .width(120)
    .height(80)
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text(this.currentMonth)
          .fontSize(20)
          .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
          .fontColor(BookingConstants.TEXT_PRIMARY_COLOR)
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
            .fontColor(BookingConstants.TEXT_SECONDARY_COLOR)
            .margin({ bottom: 4 })
          Text(`¥${this.income.toFixed(2)}`)
            .fontSize(20)
            .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
            .fontColor(BookingConstants.TEXT_INCOME_COLOR)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Divider()
          .vertical(true)
          .height(40)
          .color('#EEEEEE')

        Column() {
          Text($r('app.string.expense'))
            .fontSize(14)
            .fontColor(BookingConstants.TEXT_SECONDARY_COLOR)
            .margin({ bottom: 4 })
          Text(`¥${this.expense.toFixed(2)}`)
            .fontSize(20)
            .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
            .fontColor(BookingConstants.TEXT_EXPENSE_COLOR)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Divider()
          .vertical(true)
          .height(40)
          .color('#EEEEEE')

        Column() {
          Text($r('app.string.balance'))
            .fontSize(14)
            .fontColor(BookingConstants.TEXT_SECONDARY_COLOR)
            .margin({ bottom: 4 })
          Text(`¥${this.balance.toFixed(2)}`)
            .fontSize(20)
            .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
            .fontColor(this.balance >= 0 ? BookingConstants.TEXT_INCOME_COLOR : BookingConstants.TEXT_EXPENSE_COLOR)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
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
                .fontColor('#999999')
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
                        .fontColor(Color.White)
                        .backgroundColor(record.type === BookingConstants.RECORD_TYPE_INCOME ? 
                          BookingConstants.TEXT_INCOME_COLOR : BookingConstants.TEXT_EXPENSE_COLOR)
                        .borderRadius(4)
                        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                        .margin({ left: 8 })
                    }
                    Blank()
                    Text(record.type === BookingConstants.RECORD_TYPE_INCOME ? '+' : '-')
                      .fontSize(16)
                      .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
                      .fontColor(record.type === BookingConstants.RECORD_TYPE_INCOME ? 
                        BookingConstants.TEXT_INCOME_COLOR : BookingConstants.TEXT_EXPENSE_COLOR)
                    Text(`${record.amount.toFixed(2)}`)
                      .fontSize(16)
                      .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
                      .fontColor(record.type === BookingConstants.RECORD_TYPE_INCOME ? 
                        BookingConstants.TEXT_INCOME_COLOR : BookingConstants.TEXT_EXPENSE_COLOR)
                  }
                  .width('100%')

                  Row() {
                    Text(record.description || '')
                      .fontSize(14)
                      .fontColor('#999999')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Blank()
                    Text(DateUtils.formatDate(record.recordTime))
                      .fontSize(14)
                      .fontColor('#999999')
                  }
                  .width('100%')
                  .margin({ top: 4 })
                }
                .layoutWeight(1)
              }
              .width('100%')
              .padding(16)
              .backgroundColor(record.type === BookingConstants.RECORD_TYPE_INCOME ? 
                BookingConstants.LIGHT_INCOME_BG_COLOR : BookingConstants.LIGHT_EXPENSE_BG_COLOR)
              .borderRadius(8)
              .border({
                width: 1,
                color: record.type === BookingConstants.RECORD_TYPE_INCOME ? 
                  '#E1F7F5' : '#FFE8E0',
                style: BorderStyle.Solid
              })
              .margin({ bottom: 10 })
            }
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

      // 底部操作栏
      Row() {
        Button() {
          Column() {
            Image($r('app.media.ic_statistics_cartoon_new'))
              .width(24)
              .height(24)
              .margin({ bottom: 4 })
            Text($r('app.string.statistics'))
              .fontSize(12)
              .fontColor(BookingConstants.TEXT_PRIMARY_COLOR)
          }
        }
        .backgroundColor(Color.Transparent)
        .width(80)
        .height(80)
        .onClick(() => {
          this.goToStatistics();
        })

        Button() {
          Column() {
            Image($r('app.media.ic_add_cartoon_new'))
              .width(50)
              .height(50)
            Text($r('app.string.add_record'))
              .fontSize(12)
              .fontColor(BookingConstants.TEXT_PRIMARY_COLOR)
              .margin({ top: 4 })
          }
        }
        .backgroundColor(Color.Transparent)
        .width(80)
        .height(80)
        .onClick(() => {
          this.goToAddRecord();
        })

        Button() {
          Column() {
            Image($r('app.media.ic_profile_cartoon'))
              .width(24)
              .height(24)
              .margin({ bottom: 4 })
            Text($r('app.string.mine'))
              .fontSize(12)
              .fontColor(BookingConstants.TEXT_PRIMARY_COLOR)
          }
        }
        .backgroundColor(Color.Transparent)
        .width(80)
        .height(80)
      }
      .width('100%')
      .backgroundColor(Color.White)
      .justifyContent(FlexAlign.SpaceAround)
      .shadow({ radius: 5, color: '#0D000000', offsetY: -2 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BookingConstants.BG_COLOR_WHITE)
  }
}
