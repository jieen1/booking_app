import { BookingConstants } from '../constants/BookingConstants';
import { DateUtils } from '../utils/DateUtils';
import { RecordWithCategory } from '../model/RecordWithCategory';
import { RecordDBHelper } from '../database/RecordDBHelper';
import { BookDBHelper } from '../database/BookDBHelper';
import prompt from '@ohos.promptAction';
import { CategoryDBHelper } from '../database/CategoryDBHelper';
import { CategoryModel } from '../model/CategoryModel';
import { IconUtils } from '../utils/IconUtils';
import { RecordModel } from '../model/RecordModel';
import { AccountBookModel } from '../model/AccountBookModel';

interface GeneratedTypeLiteralInterface_1 {
  x: string;
  y: number;
}

interface GeneratedTypeLiteralInterface_2 {
  name: string;
  value: number;
  color: string;
}

@Entry
@Component
export default struct HomePage {
  @State totalAssets: number = 0;
  @State monthlyIncome: number = 0;
  @State monthlyExpense: number = 0;
  @State amount: string = '';
  @State monthlyBalance: number = 0;
  @State growthRate: number = 0;
  @State recordDate: Date = new Date();
  @State currentMonth: string = DateUtils.getCurrentMonthStr();
  @State recentRecords: RecordWithCategory[] = [];
  @State selectedType: number = BookingConstants.EXPENSE_TYPE;
  @State categories: CategoryModel[] = [];
  @State selectedCategory: CategoryModel | null = null;
  @State selectedAccountId: number = 1;
  @State selectedAccountName: string = '';
  @State accountBooks: AccountBookModel[] = [];
  @State assetTrendData: Array<GeneratedTypeLiteralInterface_1> = [];
  @State assetDistribution: Array<GeneratedTypeLiteralInterface_2> = [
    {name: '现金账户', value: 35, color: '#4080FF'},
    {name: '投资账户', value: 30, color: '#00C853'},
    {name: '基金账户', value: 20, color: '#FFA500'},
    {name: '其他资产', value: 15, color: '#9C27B0'}
  ];

  private bookDBHelper: BookDBHelper = BookDBHelper.getInstance();
  private recordDBHelper: RecordDBHelper = RecordDBHelper.getInstance();
  private categoryDBHelper: CategoryDBHelper = CategoryDBHelper.getInstance();

  aboutToAppear() {
    this.loadData();
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
      '',
      this.recordDate.getTime(),
      this.selectedAccountId
    );

    // 保存记录
    const result = await this.recordDBHelper.insertRecord(record);

    if (result > 0) {
      // 更新账本余额
      const amount = parseFloat(this.amount);
      if (this.selectedType === BookingConstants.INCOME_TYPE) {
        await this.bookDBHelper.updateAccountBalance(this.selectedAccountId, amount);
      } else {
        await this.bookDBHelper.updateAccountBalance(this.selectedAccountId, -amount);
      }

      AlertDialog.show({
        title: '成功',
        message: '记账成功',
        confirm: {
          value: '确定',
          action: () => {
          }
        }
      });
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

  async loadData() {
    try {
      // 初始化账本数据库
      await this.bookDBHelper.initDatabase();
      await this.categoryDBHelper.initDatabase();
      await this.recordDBHelper.initDatabase();

      // 加载记录数据
      await this.loadRecordData();

      // 生成资产趋势数据（示例数据）
      this.generateAssetTrendData();

      // 加载账本列表
      try {
        this.accountBooks = await this.bookDBHelper.getAllAccountBooks();
        if (this.accountBooks.length > 0) {
          // 默认选择默认账本
          const defaultAccount = this.accountBooks.find(account => account.isDefault === BookingConstants.ACCOUNT_IS_DEFAULT);
          if (defaultAccount && defaultAccount.id !== undefined) {
            this.selectedAccountId = defaultAccount.id;
            this.selectedAccountName = defaultAccount.name;
          } else if (this.accountBooks[0].id !== undefined) {
            this.selectedAccountId = this.accountBooks[0].id;
            this.selectedAccountName = this.accountBooks[0].name;
          }
        }
      } catch (error) {
        console.error('[aboutToAppear] 加载账本失败：', error);
      }

      // 加载分类
      try {
        // 加载当前类型的分类
        this.categories = await this.categoryDBHelper.getAllCategories(this.selectedType);

        if (this.categories.length > 0) {
          this.selectedCategory = this.categories[0];
        }

        console.info(`[aboutToAppear] 已加载${this.categories.length}个${this.selectedType ===
        BookingConstants.INCOME_TYPE ? '收入' : '支出'}分类`);
      } catch (error) {
        console.error('[aboutToAppear] 加载分类失败：', error);
      }

    } catch (error) {
      console.error('加载数据失败:', JSON.stringify(error));
      prompt.showToast({
        message: '加载数据失败',
        duration: 2000
      });
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
      this.categories = await this.categoryDBHelper.getAllCategories(type);

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

  async loadRecordData() {
    try {
      // 获取本月记录
      const now = new Date();
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).getTime();
      const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59).getTime();

      // 获取所有记录
      const records = await this.recordDBHelper.getRecordsWithCategory(this.selectedAccountId);

      // 获取最近交易记录（最多5条）
      this.recentRecords = records.slice(0, 5);

      // 计算月收入和支出
      this.monthlyIncome = 0;
      this.monthlyExpense = 0;

      records.forEach(record => {
        if (record.recordTime >= startOfMonth && record.recordTime <= endOfMonth) {
          if (record.type === BookingConstants.RECORD_TYPE_INCOME) {
            this.monthlyIncome += record.amount;
          } else {
            this.monthlyExpense += record.amount;
          }
        }
      });

      // 计算月结余
      this.monthlyBalance = this.monthlyIncome - this.monthlyExpense;

      // 设置总资产（示例数据）
      this.totalAssets = 128500.00;

      // 设置增长率（示例数据）
      this.growthRate = 3.2;

    } catch (error) {
      console.error('加载记录数据失败:', JSON.stringify(error));
    }
  }

  generateAssetTrendData() {
    // 生成示例资产趋势数据
    const days = ['3.1', '3.5', '3.10', '3.15', '3.20', '3.25', '3.30'];
    const values = [110000, 112000, 115000, 118000, 120000, 125000, 128500];

    this.assetTrendData = days.map((day, index) => {
      let a: GeneratedTypeLiteralInterface_1 = {
        x: day,
        y: values[index]
      };
      return a;
    });
  }

  build() {
    Column() {
      Row()
        .height(20)

      // 顶部标题栏
      Row() {
        Text('总资产')
          .fontSize(16)
          .fontColor($r('app.color.TEXT_SECONDARY_COLOR'))

        Blank()

        Text(`${this.currentMonth}`)
          .fontSize(14)
          .fontColor($r('app.color.TEXT_SECONDARY_COLOR'))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16 })

      Row() {
        // 总资产显示
        Column() {
          Text(`¥${this.totalAssets.toFixed(2)}`)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
            .margin({ top: 8, bottom: 8 })

          Row() {
            Image($r('app.media.ic_arrow_up'))
              .width(16)
              .height(16)
              .margin({ right: 4 })

            Text(`较上月 +${this.growthRate}%`)
              .fontSize(14)
              .fontColor('#4CAF50')
          }

          // 月收支信息
          Row() {
            Column() {
              Text($r('app.string.income'))
                .fontSize(14)
                .fontColor($r('app.color.TEXT_SECONDARY_COLOR'))

                .margin({ bottom: 4 })

              Text(`¥${this.monthlyIncome.toFixed(2)}`)
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
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

              Text(`¥${this.monthlyExpense.toFixed(2)}`)
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
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

              Text(`¥${this.monthlyBalance.toFixed(2)}`)
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.monthlyBalance >= 0 ? $r('app.color.TEXT_INCOME_COLOR') : $r('app.color.TEXT_EXPENSE_COLOR'))
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .padding({ top: 16, bottom: 16 })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        // .padding({ left: 16, right: 16 })
      }
      .height(150)
      .width('95%')
      .borderRadius(16)
      .backgroundColor($r('app.color.BG_COLOR_SECONDARY'))
      .padding(10)
      .margin({ bottom: 16 })
      .shadow(ShadowStyle.OUTER_DEFAULT_SM)


      // 快速记账区域
      Row() {
        Text('快速记账')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))

        Blank()

        Text(`${this.selectedAccountName}`)
          .fontSize(14)
          .fontColor($r('app.color.TEXT_SECONDARY_COLOR'))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
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

        // 金额输入框
        TextInput({ placeholder: '0.00' })
          .type(InputType.NUMBER_DECIMAL)
          .placeholderColor($r('app.color.TEXT_SECONDARY_COLOR'))
          .placeholderFont({ size: 24 })
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
          .textAlign(TextAlign.Center)
          .border({width: 1, color: $r('app.color.BORDER_COLOR')})
          .width('90%')
          .height(50)
          .margin({ bottom: 4 })
          .onChange((value) => {
            this.amount = value;
          })

        Row() {

          Button('当天')
            .onClick(() => {
              this.recordDate = new Date();
            })
            .width(60)
            .height(40)
            .fontSize(14)
            .margin(10)
            .backgroundColor(DateUtils.getDateStr(this.recordDate.getTime()) == DateUtils.getDateStr(new Date().getTime()) ? $r('app.color.SUCCESS_COLOR') : $r('app.color.BG_COLOR'))

          Button('昨天')
            .onClick(() => {
              this.recordDate = new Date(new Date().getTime() - 24 * 60 * 60 * 1000);
            })
            .width(60)
            .height(40)
            .fontSize(14)
            .margin(10)
            .backgroundColor(DateUtils.getDateStr(this.recordDate.getTime()) == DateUtils.getDateStr(new Date().getTime() - 24 * 60 * 60 * 1000) ? $r('app.color.SUCCESS_COLOR') : $r('app.color.BG_COLOR'))

          Button('前天')
            .onClick(() => {
              this.recordDate = new Date(new Date().getTime() - 24 * 60 * 60 * 2 * 1000);
            })
            .width(60)
            .height(40)
            .fontSize(14)
            .margin(10)
            .backgroundColor(DateUtils.getDateStr(this.recordDate.getTime()) == DateUtils.getDateStr(new Date().getTime() - 24 * 60 * 60 * 1000 * 2) ? $r('app.color.SUCCESS_COLOR') : $r('app.color.BG_COLOR'))

        }

        // 平铺显示分类
        Scroll() {
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            ForEach(this.categories, (category: CategoryModel) => {
              Column() {
                Image(IconUtils.getCategoryIcon(category.icon))
                  .width(40)
                  .height(40)
                  .margin({ bottom: 2 })

                Text(category.name)
                  .fontSize(12)
                  .fontColor(this.selectedCategory?.id === category.id ?
                  $r('app.color.TEXT_PRIMARY_COLOR') : $r('app.color.TEXT_SECONDARY_COLOR'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width(60)
              .height(60)
              .margin(4)
              .padding(2)
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
        .height(160)
        .scrollBar(BarState.Off)

        // 保存按钮
        Button('保存')
          .width('90%')
          .height(50)
          .fontSize(18)
          .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
          .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
          .backgroundColor($r('app.color.SUCCESS_COLOR'))
          .margin({ top: 10, bottom: 8 })
          .borderRadius(25)
          .onClick(() => {
            this.saveRecord();
          })
      }
      .width('95%')
      .borderRadius(16)
      .backgroundColor($r('app.color.BG_COLOR_SECONDARY'))
      .padding({ bottom: 16 })
      .shadow(ShadowStyle.OUTER_DEFAULT_SM)

      // 财务概览标题
      Row() {
        Text('财务概览')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))

        Blank()

        Text('查看全部 >')
          .fontSize(14)
          .fontColor('#2196F3')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 8 })

      // 图表区域（水平滚动）
      Swiper() {
        // 资产趋势图
        Column() {
          Row() {
            Text('资产趋势')
              .fontSize(16)
              .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))

            Blank()

            Image($r('app.media.ic_fullscreen'))
              .width(20)
              .height(20)
          }
          .width('100%')
          .padding({ bottom: 8 })

          // 趋势图（简化版）
          Stack() {
            Polyline()
              .width('100%')
              .height('100%')
              .points(this.assetTrendData.map((item, index) => {
                let a: GeneratedTypeLiteralInterface_1 = {
                  x: (index * (300 / (this.assetTrendData.length - 1))) + "",
                  y: 150 - (item.y - 110000) / 200
                };
                return a;
              }))
              .stroke('#2196F3')
              .strokeWidth(2)
              .fillOpacity(0.1)
              .fill('#E3F2FD')

            // X轴标签
            Row() {
              ForEach(this.assetTrendData, (item: GeneratedTypeLiteralInterface_1) => {
                Text(item.x)
                  .fontSize(12)
                  .fontColor($r('app.color.TEXT_SECONDARY_COLOR'))
                  .layoutWeight(1)
                  .textAlign(TextAlign.Center)
              })
            }
            .width('100%')
            .position({ x: 0, y: '100%' })
          }
          .width('100%')
          .height(150)
          .backgroundColor($r('app.color.BG_COLOR'))
          .padding(16)
        }
        .width('100%')
        .height(220)
        .backgroundColor($r('app.color.BG_COLOR_SECONDARY'))
        .borderRadius(16)
        .margin({ left: 16, right: 16 })

        // 资产分布图
        Column() {
          Row() {
            Text('资产分布')
              .fontSize(16)
              .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))

            Blank()

            Image($r('app.media.ic_fullscreen'))
              .width(20)
              .height(20)
          }
          .width('100%')
          .padding({ bottom: 8 })

          // 饼图（简化版）
          Row() {
            // 左侧饼图
            Stack() {
              // 简化的饼图表示
              Circle()
                .width(120)
                .height(120)
                .fill('#4080FF')
                .opacity(0.8)

              Circle()
                .width(120)
                .height(120)
                .fill('#00C853')
                .opacity(0.8)
                .clip(new Rect({
                  width: 60, height: 120
                }))

              Circle()
                .width(120)
                .height(120)
                .fill('#FFA500')
                .opacity(0.8)
                .clip(new Rect({
                  width: 60, height: 60
                }))

              Circle()
                .width(120)
                .height(120)
                .fill('#9C27B0')
                .opacity(0.8)
                .clip(new Rect({
                  width: 30, height: 60
                }))
            }
            .width(120)
            .height(120)

            // 右侧图例
            Column() {
              ForEach(this.assetDistribution, (item: GeneratedTypeLiteralInterface_2) => {
                Row() {
                  Circle()
                    .width(10)
                    .height(10)
                    .fill(item.color)
                    .margin({ right: 8 })

                  Text(item.name)
                    .fontSize(14)
                    .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
                    .layoutWeight(1)

                  Text(`${item.value}%`)
                    .fontSize(14)
                    .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
                }
                .width('100%')
                .margin({ bottom: 8 })
              })
            }
            .layoutWeight(1)
            .margin({ left: 16 })
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(16)
        }
        .width('100%')
        .height(220)
        .backgroundColor($r('app.color.BG_COLOR_SECONDARY'))
        .borderRadius(16)
        .margin({ left: 16, right: 16 })

        // 支出分类
        Column() {
          Row() {
            Text('支出分类')
              .fontSize(16)
              .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))

            Blank()

            Image($r('app.media.ic_fullscreen'))
              .width(20)
              .height(20)
          }
          .width('100%')
          .padding({ bottom: 8 })

          // 分类标签
          Row() {
            ForEach(['餐饮', '购物', '交通', '居住'], (item: string) => {
              Text(item)
                .fontSize(14)
                .fontColor(item === '餐饮' ? '#FFFFFF' : $r('app.color.TEXT_PRIMARY_COLOR'))
                .backgroundColor(item === '餐饮' ? '#2196F3' : '#F5F5F5')
                .borderRadius(16)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .margin({ right: 8 })
            })
          }
          .width('100%')
          .padding({ bottom: 16 })

          // 简化的柱状图
          Column() {
            Row() {
              Column()
                .width(30)
                .height(80)
                .backgroundColor('#F44336')
                .borderRadius({ topLeft: 4, topRight: 4 })

              Column()
                .width(30)
                .height(60)
                .backgroundColor('#4CAF50')
                .borderRadius({ topLeft: 4, topRight: 4 })
                .margin({ left: 16 })

              Column()
                .width(30)
                .height(40)
                .backgroundColor('#2196F3')
                .borderRadius({ topLeft: 4, topRight: 4 })
                .margin({ left: 16 })

              Column()
                .width(30)
                .height(20)
                .backgroundColor('#FFC107')
                .borderRadius({ topLeft: 4, topRight: 4 })
                .margin({ left: 16 })
            }
            .width('100%')
            .alignItems(VerticalAlign.Bottom)

            Row() {
              Text('餐饮')
                .fontSize(12)
                .fontColor($r('app.color.TEXT_SECONDARY_COLOR'))
                .width(30)
                .textAlign(TextAlign.Center)

              Text('购物')
                .fontSize(12)
                .fontColor($r('app.color.TEXT_SECONDARY_COLOR'))
                .width(30)
                .textAlign(TextAlign.Center)
                .margin({ left: 16 })

              Text('交通')
                .fontSize(12)
                .fontColor($r('app.color.TEXT_SECONDARY_COLOR'))
                .width(30)
                .textAlign(TextAlign.Center)
                .margin({ left: 16 })

              Text('居住')
                .fontSize(12)
                .fontColor($r('app.color.TEXT_SECONDARY_COLOR'))
                .width(30)
                .textAlign(TextAlign.Center)
                .margin({ left: 16 })
            }
            .width('100%')
            .margin({ top: 8 })
          }
          .width('100%')
          .padding(16)
        }
        .width('100%')
        .height(220)
        .backgroundColor($r('app.color.BG_COLOR'))
        .borderRadius(16)
        .margin({ left: 16, right: 16 })
      }
      .indicator(true)
      .indicatorStyle({
        selectedColor: '#2196F3',
        color: '#BDBDBD',
        size: 8,
        mask: true
      })
      .loop(true)
      .height(220)
      .margin({ bottom: 16 })
      .width('95%')
      .borderRadius(16)
      .backgroundColor($r('app.color.BG_COLOR_SECONDARY'))
      .padding({ bottom: 16 })
      .shadow(ShadowStyle.OUTER_DEFAULT_SM)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.BG_COLOR'))
  }
}