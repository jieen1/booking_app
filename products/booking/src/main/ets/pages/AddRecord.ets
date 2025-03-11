import { router } from '@kit.ArkUI';
import { BookingConstants } from '../constants/BookingConstants';
import { CategoryModel } from '../model/CategoryModel';
import { RecordModel } from '../model/RecordModel';
import { DateUtils } from '../utils/DateUtils';
import prompt from '@ohos.promptAction';
import { IconUtils } from '../utils/IconUtils';
import { CategoryDBHelper } from '../database/CategoryDBHelper';
import { RecordDBHelper } from '../database/RecordDBHelper';
import { BookDBHelper } from '../database/BookDBHelper';
import { AccountBookModel } from '../model/AccountBookModel';


@Entry
@Component
export default struct AddRecord {
  @State selectedType: number = BookingConstants.EXPENSE_TYPE;
  @State categories: CategoryModel[] = [];
  @State selectedCategory: CategoryModel | null = null;
  @State amount: string = '';
  @State description: string = '';
  @State recordDate: Date = new Date();
  @State showDatePicker: boolean = false;
  @State accountBooks: AccountBookModel[] = [];
  @State selectedAccountId: number = 0;
  @State showAccountBookSelector: boolean = false;
  private dbHelper: CategoryDBHelper = CategoryDBHelper.getInstance();
  private bookDBHelper: BookDBHelper = BookDBHelper.getInstance();

  async aboutToAppear() {
    console.info('[aboutToAppear] 页面即将显示，开始初始化');

    // 初始化数据库
    await this.dbHelper.initDatabase();
    await this.bookDBHelper.initDatabase();

    // 加载账本列表
    try {
      this.accountBooks = await this.bookDBHelper.getAllAccountBooks();
      if (this.accountBooks.length > 0) {
        // 默认选择默认账本
        const defaultAccount = this.accountBooks.find(account => account.isDefault === BookingConstants.ACCOUNT_IS_DEFAULT);
        if (defaultAccount && defaultAccount.id !== undefined) {
          this.selectedAccountId = defaultAccount.id;
        } else if (this.accountBooks[0].id !== undefined) {
          this.selectedAccountId = this.accountBooks[0].id;
        }
      }
    } catch (error) {
      console.error('[aboutToAppear] 加载账本失败：', error);
    }

    // 加载分类
    try {
      // 加载当前类型的分类
      this.categories = await this.dbHelper.getAllCategories(this.selectedType);

      if (this.categories.length > 0) {
        this.selectedCategory = this.categories[0];
      }

      console.info(`[aboutToAppear] 已加载${this.categories.length}个${this.selectedType ===
      BookingConstants.INCOME_TYPE ? '收入' : '支出'}分类`);
    } catch (error) {
      console.error('[aboutToAppear] 加载分类失败：', error);
    }
  }

  async switchType(type: number) {
    if (this.selectedType === type) {
      return; // 防止重复切换
    }

    this.selectedType = type;

    try {
      console.info(`[switchType] 从类型${this.selectedType === BookingConstants.INCOME_TYPE ? '收入' :
        '支出'}切换到${type === BookingConstants.INCOME_TYPE ? '收入' : '支出'}`);

      // 重新加载分类
      this.categories = await this.dbHelper.getAllCategories(type);

      // 更新选中的分类
      if (this.categories.length > 0) {
        this.selectedCategory = this.categories[0];
      } else {
        this.selectedCategory = null;
      }

      console.info(`[switchType] 加载了${this.categories.length}个${type === BookingConstants.INCOME_TYPE ? '收入' :
        '支出'}分类`);
    } catch (error) {
      console.error('[switchType] 切换类型加载分类失败：', error);
    }
  }

  async saveRecord() {
    // 验证输入
    if (!this.selectedCategory) {
      AlertDialog.show({
        title: '提示',
        message: '请选择类别',
        confirm: {
          value: '确定',
          action: () => {
          }
        }
      });
      return;
    }

    if (!this.amount || parseFloat(this.amount) === 0) {
      AlertDialog.show({
        title: '提示',
        message: '请输入金额',
        confirm: {
          value: '确定',
          action: () => {
          }
        }
      });
      return;
    }

    if (this.selectedAccountId <= 0) {
      AlertDialog.show({
        title: '提示',
        message: '请选择账本',
        confirm: {
          value: '确定',
          action: () => {
          }
        }
      });
      return;
    }

    // 创建记录对象
    const record = new RecordModel(
      this.selectedType,
      this.selectedCategory.id!,
      parseFloat(this.amount),
      this.description,
      this.recordDate.getTime(),
      this.selectedAccountId
    );

    // 保存记录
    const result = await RecordDBHelper.getInstance().insertRecord(record);

    if (result > 0) {
      // 更新账本余额
      const amount = parseFloat(this.amount);
      if (this.selectedType === BookingConstants.INCOME_TYPE) {
        await this.bookDBHelper.updateAccountBalance(this.selectedAccountId, amount);
      } else {
        await this.bookDBHelper.updateAccountBalance(this.selectedAccountId, -amount);
      }
    } else {
      AlertDialog.show({
        title: '错误',
        message: '保存失败，请重试',
        confirm: {
          value: '确定',
          action: () => {
          }
        }
      });
    }
  }

  showAccountBookList() {
    this.showAccountBookSelector = true;
  }
  
  selectAccountBook(accountId: number): void {
    this.selectedAccountId = accountId;
    this.showAccountBookSelector = false;
  }

  build() {
    Column() {
      Row()
        .height(20)

      // 顶部标题栏
      Row() {

        Text('添加记录')
          .fontSize(18)
          .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
          .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
          .margin({ left: 16 })

        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor($r('app.color.BG_COLOR'))

      Scroll() {
        Column() {
          // 收入/支出切换
          Row() {
            Row() {
              Button('支出')
                .onClick(() => {
                  this.switchType(BookingConstants.EXPENSE_TYPE);
                })
                .width(80)
                .height(36)
                .fontSize(16)
                .fontWeight(this.selectedType === BookingConstants.EXPENSE_TYPE ?
                BookingConstants.FONT_WEIGHT_MEDIUM : BookingConstants.FONT_WEIGHT_NORMAL)
                .fontColor(this.selectedType === BookingConstants.EXPENSE_TYPE ?
                $r('app.color.BG_COLOR') : $r('app.color.TEXT_PRIMARY_COLOR'))
                .backgroundColor(this.selectedType === BookingConstants.EXPENSE_TYPE ?
                $r('app.color.PRIMARY_COLOR') : $r('app.color.BG_COLOR'))
                .borderRadius(18)
                .margin({ right: 16 })

              Button('收入')
                .onClick(() => {
                  this.switchType(BookingConstants.INCOME_TYPE);
                })
                .width(80)
                .height(36)
                .fontSize(16)
                .fontWeight(this.selectedType === BookingConstants.INCOME_TYPE ?
                BookingConstants.FONT_WEIGHT_MEDIUM : BookingConstants.FONT_WEIGHT_NORMAL)
                .fontColor(this.selectedType === BookingConstants.INCOME_TYPE ?
                $r('app.color.BG_COLOR') : $r('app.color.TEXT_PRIMARY_COLOR'))
                .backgroundColor(this.selectedType === BookingConstants.INCOME_TYPE ?
                $r('app.color.SUCCESS_COLOR') : $r('app.color.BG_COLOR'))
                .borderRadius(18)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ top: 8, bottom: 16 })
          }
          .width('100%')

          // 金额输入
          Row() {
            Text('￥')
              .fontSize(32)
              .fontColor(this.selectedType === BookingConstants.INCOME_TYPE ?
              $r('app.color.TEXT_INCOME_COLOR') : $r('app.color.TEXT_EXPENSE_COLOR'))
              .fontWeight(BookingConstants.FONT_WEIGHT_BOLD)
              .margin({ right: 4 })
            TextInput({
              placeholder: '0.00',
              text: this.amount
            })
              .fontSize(40)
              .fontColor(this.selectedType === BookingConstants.INCOME_TYPE ?
              $r('app.color.TEXT_INCOME_COLOR') : $r('app.color.TEXT_EXPENSE_COLOR'))
              .fontWeight(BookingConstants.FONT_WEIGHT_BOLD)
              .backgroundColor(Color.Transparent)
              .type(InputType.NUMBER_DECIMAL)
              .maxLength(14)
              .onChange((value) => {
                this.amount = value;
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 20, bottom: 10, left: 20 })
          .backgroundColor($r('app.color.BG_COLOR'))
          .margin({ left: 16, right: 16 })
          .borderRadius(8)

          // 账本选择
          Row() {
            Text('账本')
              .fontSize(16)
              .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
              .width(80)

            if (this.accountBooks.length > 0) {
              Row() {
                Text(this.accountBooks.find(account => account.id === this.selectedAccountId)?.name)
                  .fontSize(16)
                  .fontColor($r('app.color.TEXT_SECONDARY_COLOR'))
                  .layoutWeight(1)

                Image($r('app.media.ic_left_cartoon_new'))
                  .width(24)
                  .height(24)
                  .margin({ left: 8 })
              }
              .layoutWeight(1)
            } else {
              Text('请选择账本')
                .fontSize(16)
                .fontColor($r('app.color.TEXT_HINT_COLOR'))
                .layoutWeight(1)
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.BG_COLOR'))
          .margin({ left: 16, right: 16, top: 10 })
          .borderRadius(8)
          .onClick(() => {
            // 显示账本选择弹窗
            this.showAccountBookList();
          })

          // 信息输入区域
          Column() {
            // 分类选择
            Column() {
              Row() {
                Text('分类')
                  .fontSize(16)
                  .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
                  .width(80)

                if (this.selectedCategory) {
                  Row() {
                    Image(IconUtils.getCategoryIcon(this.selectedCategory.icon))
                      .width(24)
                      .height(24)
                      .margin({ right: 8 })

                    Text(this.selectedCategory.name)
                      .fontSize(16)
                      .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
                      .layoutWeight(1)
                  }
                  .layoutWeight(1)
                } else {
                  Text('请选择分类')
                    .fontSize(16)
                    .fontColor($r('app.color.TEXT_HINT_COLOR'))
                    .layoutWeight(1)
                }
              }
              .width('100%')
              .padding(16)

              // 平铺显示分类
              Scroll() {
                Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                  ForEach(this.categories, (category: CategoryModel) => {
                    Column() {
                      Image(IconUtils.getCategoryIcon(category.icon))
                        .width(40)
                        .height(40)
                        .margin({ bottom: 4 })

                      Text(category.name)
                        .fontSize(12)
                        .fontColor(this.selectedCategory?.id === category.id ?
                        $r('app.color.TEXT_PRIMARY_COLOR') : $r('app.color.TEXT_SECONDARY_COLOR'))
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .width(60)
                    .height(70)
                    .margin(8)
                    .padding(4)
                    .borderRadius(8)
                    .backgroundColor(this.selectedCategory?.id === category.id ?
                    $r('app.color.BG_COLOR_SECONDARY') : Color.Transparent)
                    .border({
                      width: this.selectedCategory?.id === category.id ? 1 : 0,
                      color: $r('app.color.BORDER_COLOR')
                    })
                    .onClick(() => {
                      this.selectedCategory = category;
                      console.info(`选择分类: ${category.name}, ID: ${category.id}`);
                    })
                  })
                }
                .padding(8)
              }
              .height(170)
              .scrollBar(BarState.Off)
            }
            .width('100%')
            .backgroundColor($r('app.color.BG_COLOR'))
            .margin({ left: 16, right: 16, top: 16 })
            .borderRadius(8)

            Divider()
              .color($r('sys.color.ohos_id_color_list_separator'))

            // 备注输入
            Row() {
              Text('备注')
                .fontSize(16)
                .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
                .width(80)

              TextInput({ placeholder: '添加备注...', text: this.description })
                .fontSize(16)
                .fontColor($r('app.color.TEXT_SECONDARY_COLOR'))
                .placeholderColor($r('app.color.TEXT_HINT_COLOR'))
                .backgroundColor(Color.Transparent)
                .layoutWeight(1)
                .height(40)
                .border({ width: 0 })
                .onChange((value: string) => {
                  this.description = value;
                })
            }
            .width('100%')
            .backgroundColor($r('app.color.BG_COLOR'))
            .padding({
              left: 16,
              right: 16,
              top: 16,
              bottom: 16
            })
            .margin({ left: 16, right: 16, top: 8 })
            .borderRadius(8)

            Divider()
              .color($r('sys.color.ohos_id_color_list_separator'))

            // 日期选择
            Row() {
              Text('日期')
                .fontSize(16)
                .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
                .width(80)

              Text(DateUtils.formatDate(this.recordDate, 'yyyy-MM-dd'))
                .fontSize(16)
                .fontColor($r('app.color.TEXT_SECONDARY_COLOR'))
                .layoutWeight(1)

              Image($r('app.media.ic_calendar_cartoon_new'))
                .width(24)
                .height(24)
                .margin({ left: 8 })
            }
            .width('100%')
            .backgroundColor($r('app.color.BG_COLOR'))
            .padding({
              left: 16,
              right: 16,
              top: 16,
              bottom: 16
            })
            .margin({ left: 16, right: 16, top: 8 })
            .borderRadius(8)
            .onClick(() => {
              try {
                let datePickerOptions: DatePickerDialogOptions = {
                  start: new Date("2020-1-1"), // 可选起始日期
                  end: new Date(), // 可选结束日期
                  selected: this.recordDate, // 默认选中日期
                  lunar: false, // 是否显示农历
                  onAccept: (value: DatePickerResult) => {
                    console.info('选择日期: ' + JSON.stringify(value));
                    const year = value.year !== undefined ? value.year : new Date().getFullYear();
                    const month = value.month !== undefined ? value.month : new Date().getMonth();
                    const day = value.day !== undefined ? value.day : new Date().getDate();
                    this.recordDate = new Date(year, month, day);
                  },
                  onCancel: () => {
                    console.info('取消选择日期');
                  }
                };

                DatePickerDialog.show(datePickerOptions);
              } catch (error) {
                console.error('显示日期选择器错误: ' + JSON.stringify(error));
                // 显示提示
                prompt.showToast({
                  message: '无法打开日期选择器，请稍后重试',
                  duration: 2000
                });
              }
            })

            // 保存按钮
            Button('保存')
              .width('90%')
              .height(50)
              .fontSize(18)
              .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
              .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
              .backgroundColor($r('app.color.SUCCESS_COLOR'))
              .margin({ top: 20, bottom: 16 })
              .borderRadius(25)
              .onClick(() => {
                this.saveRecord();
              })
          }

          // 日期选择弹窗
          if (this.showDatePicker) {
            Column()
              .width('100%')
              .height('100%')
              .backgroundColor($r('app.color.BG_COLOR_SECONDARY'))
              .onClick(() => {
                this.showDatePicker = false
              })
          }
          
          // 账本选择弹窗
          if (this.showAccountBookSelector) {
            Column() {
              // 遮罩层
              Column()
                .width('100%')
                .height('100%')
                .backgroundColor('#88000000')
                .position({ x: 0, y: 0 })
                .onClick(() => {
                  this.showAccountBookSelector = false;
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
                          this.selectAccountBook(account.id);
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
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.BG_COLOR'))
      .scrollBar(BarState.Off)
      .width('100%')
      .height('100%')

      Row()
        .height(15)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.BG_COLOR'))
  }
}
