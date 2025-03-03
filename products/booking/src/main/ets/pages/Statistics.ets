import { router } from '@kit.ArkUI';
import { BookingConstants } from '../constants/BookingConstants';
import { DBHelper } from '../database/DBHelper';
import { DateUtils } from '../utils/DateUtils';

// 分类统计数据接口
interface CategoryStatistic {
  categoryId: number;
  categoryName: string;
  icon: string;
  amount: number;
}

// 收支汇总数据接口
interface SummaryData {
  income: number;
  expense: number;
}

// 扇形信息接口
interface SectorInfo {
  start: number;          // 起始角度
  end: number;            // 结束角度
  centerAngle: number;    // 中心角度
  category: CategoryStatistic; // 分类信息
}

@Entry
@Component
struct Statistics {
  @State selectedType: number = BookingConstants.EXPENSE_TYPE;
  @State isLoading: boolean = false;
  @State currentTab: number = 0; // 0: 月度, 1: 年度
  @State currentYear: number = new Date().getFullYear();
  @State currentMonth: number = new Date().getMonth();
  @State statistics: CategoryStatistic[] = [];
  @State summary: SummaryData = {
    income: 0,
    expense: 0
  };
  @State isIncome: boolean = false;
  // 添加当前选中的分类索引
  @State selectedPieIndex: number = -1;
  
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private canvasSize: number = 260;
  private colors: string[] = ['#FFA500', '#4CAF50', '#2196F3', '#9C27B0', '#E91E63', '#F44336', '#3F51B5', '#00BCD4'];
  private sectors: SectorInfo[] = [];
  
  private dbHelper: DBHelper = DBHelper.getInstance();
  private tabs: string[] = ['月度统计', '年度统计'];
  
  aboutToAppear() {
    this.loadData();
  }
  
  onPageShow() {
    // 每次页面显示时重新加载数据
    this.loadData();
  }
  
  loadData() {
    this.isLoading = true;
    this.dbHelper.initDatabase().then(() => {
      if (this.currentTab === 0) {
        // 月度统计
        const dateRange = DateUtils.getMonthRange(this.currentYear, this.currentMonth);
        // 加载统计数据
        this.dbHelper.getStatisticsByCategory(
          this.isIncome ? BookingConstants.INCOME_TYPE : BookingConstants.EXPENSE_TYPE, 
          dateRange.startTime, 
          dateRange.endTime
        ).then((stats) => {
          this.statistics = stats;
          
          // 加载收支统计
          this.dbHelper.getSummary(dateRange.startTime, dateRange.endTime).then((summaryData) => {
            this.summary = summaryData as SummaryData;
            this.isLoading = false;
          });
        });
      } else {
        // 年度统计
        const startTime = new Date(this.currentYear, 0, 1).getTime();
        const endTime = new Date(this.currentYear, 11, 31, 23, 59, 59, 999).getTime();
        // 加载统计数据
        this.dbHelper.getStatisticsByCategory(
          this.isIncome ? BookingConstants.INCOME_TYPE : BookingConstants.EXPENSE_TYPE, 
          startTime, 
          endTime
        ).then((stats) => {
          this.statistics = stats;
          
          // 加载收支统计
          this.dbHelper.getSummary(startTime, endTime).then((summaryData) => {
            this.summary = summaryData as SummaryData;
            this.isLoading = false;
          });
        });
      }
    }).catch((err: Error) => {
      console.error('加载统计数据失败:', JSON.stringify(err));
      this.isLoading = false;
    });
  }
  
  // 切换月份
  changeMonth(delta: number) {
    let newMonth = this.currentMonth + delta;
    let newYear = this.currentYear;
    
    if (newMonth < 0) {
      newMonth = 11;
      newYear--;
    } else if (newMonth > 11) {
      newMonth = 0;
      newYear++;
    }
    
    this.currentMonth = newMonth;
    this.currentYear = newYear;
    this.loadData();
  }
  
  // 切换年份
  changeYear(delta: number) {
    this.currentYear += delta;
    this.loadData();
  }
  
  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Button() {
          Image($r('app.media.ic_back_cartoon_new'))
            .width(30)
            .height(30)
            .fillColor(BookingConstants.TEXT_PRIMARY_COLOR)
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.back();
        })
        
        Text('统计')
          .fontSize(20)
          .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
          .fontColor(BookingConstants.TEXT_PRIMARY_COLOR)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        // 留出右侧平衡空间，确保标题居中
        Button() {
          Image($r('app.media.ic_back_cartoon_new'))
            .width(30)
            .height(30)
            .opacity(0)
        }
        .backgroundColor(Color.Transparent)
        .opacity(0)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      
      // Tab选择
      Row() {
        ForEach(this.tabs, (tab: string, index: number) => {
          Text(tab)
            .fontSize(16)
            .fontWeight(this.currentTab === index ? 
              BookingConstants.FONT_WEIGHT_MEDIUM : BookingConstants.FONT_WEIGHT_NORMAL)
            .fontColor(this.currentTab === index ? 
              BookingConstants.PRIMARY_COLOR : BookingConstants.TEXT_SECONDARY_COLOR)
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .onClick(() => {
              this.currentTab = index;
              this.loadData();
            })
          
          if (index < this.tabs.length - 1) {
            Divider()
              .vertical(true)
              .height(16)
              .color(BookingConstants.TEXT_HINT_COLOR)
          }
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 8 })
      
      // 时间选择器
      Row() {
        Button() {
          Image($r('app.media.ic_left_cartoon_new'))
            .width(30)
            .height(30)
            .fillColor(BookingConstants.TEXT_SECONDARY_COLOR)
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          if (this.currentTab === 0) {
            this.changeMonth(-1);
          } else {
            this.changeYear(-1);
          }
        })
        
        Text(`${this.currentYear}年${this.currentMonth + 1}月`)
          .fontSize(18)
          .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
          .fontColor(BookingConstants.TEXT_PRIMARY_COLOR)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Button() {
          Image($r('app.media.ic_right_cartoon_new'))
            .width(30)
            .height(30)
            .fillColor(BookingConstants.TEXT_SECONDARY_COLOR)
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          if (this.currentTab === 0) {
            this.changeMonth(1);
          } else {
            this.changeYear(1);
          }
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 12 })
      
      // 收入/支出切换
      Row() {
        Column() {
          Text('收入')
            .fontSize(14)
            .fontColor(this.isIncome ? BookingConstants.PRIMARY_COLOR : BookingConstants.TEXT_SECONDARY_COLOR)
            .fontWeight(this.isIncome ? BookingConstants.FONT_WEIGHT_MEDIUM : BookingConstants.FONT_WEIGHT_NORMAL)
          
          Divider()
            .width(40)
            .height(2)
            .color(this.isIncome ? BookingConstants.PRIMARY_COLOR : Color.Transparent)
            .margin({ top: 4 })
        }
        .width('50%')
        .padding({ top: 8, bottom: 8 })
        .onClick(() => {
          this.isIncome = true;
          this.loadData();
        })
        
        Column() {
          Text('支出')
            .fontSize(14)
            .fontColor(!this.isIncome ? BookingConstants.PRIMARY_COLOR : BookingConstants.TEXT_SECONDARY_COLOR)
            .fontWeight(!this.isIncome ? BookingConstants.FONT_WEIGHT_MEDIUM : BookingConstants.FONT_WEIGHT_NORMAL)
          
          Divider()
            .width(40)
            .height(2)
            .color(!this.isIncome ? BookingConstants.PRIMARY_COLOR : Color.Transparent)
            .margin({ top: 4 })
        }
        .width('50%')
        .padding({ top: 8, bottom: 8 })
        .onClick(() => {
          this.isIncome = false;
          this.loadData();
        })
      }
      .width('100%')
      .margin({ bottom: 16 })
      
      // 收支总额
      Column() {
        Text(this.isIncome ? '总收入' : '总支出')
          .fontSize(14)
          .fontColor(BookingConstants.TEXT_SECONDARY_COLOR)
        
        Text(`${this.isIncome ? this.summary.income.toFixed(2) : this.summary.expense.toFixed(2)}`)
          .fontSize(24)
          .fontWeight(BookingConstants.FONT_WEIGHT_BOLD)
          .fontColor(this.isIncome ? BookingConstants.SUCCESS_COLOR : BookingConstants.ERROR_COLOR)
          .margin({ top: 4 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .margin({ bottom: 16 })
      
      // 统计内容
      if (this.isLoading) {
        LoadingProgress()
          .width(30)
          .height(30)
          .margin(20)
      } else if (this.statistics.length === 0) {
        this.EmptyView()
      } else {
        // 将饼图和列表放在同一个Scroll中
        Scroll() {
          Column() {
            // 统计图表区域
            this.ChartArea()
            
            // 统计明细列表
            Column() {
              // 标题
              Text("分类明细")
                .fontSize(16)
                .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
                .fontColor(BookingConstants.TEXT_PRIMARY_COLOR)
                .width('100%')
                .padding({ left: 16, top: 16, bottom: 8 })
              
              // 分类列表
              List() {
                ForEach(this.statistics, (item: CategoryStatistic) => {
                  ListItem() {
                    this.CategoryListItem(item)
                  }
                }, (item: CategoryStatistic) => `${item.categoryId}`)
              }
              .width('100%')
              .divider({
                strokeWidth: 0.5,
                color: BookingConstants.BG_COLOR_GRAY,
                startMargin: 64,
                endMargin: 16
              })
              .padding({ left: 16, right: 16, bottom: 16 })
            }
            .width('100%')
            .backgroundColor(Color.White)
            .borderRadius(8)
            .margin({ left: 16, right: 16, bottom: 16 })
          }
          .width('100%')
        }
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BookingConstants.BG_COLOR_WHITE)
  }

  /**
   * 当记录为空时的UI
   */
  @Builder
  EmptyView() {
    Column() {
      Image($r(BookingConstants.EMPTY_ICON))
        .width(100)
        .height(100)
        .margin({ bottom: 16 })
      
      Text('暂无记录')
        .fontSize(16)
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
  
  @Builder
  ChartArea() {
    Column() {
      // 饼图区域
      Row() {
        Stack() {
          Canvas(this.context)
            .width(260) // 增大饼图尺寸
            .height(260) // 增大饼图尺寸
            .onReady(() => {
              this.drawPieChart(this.statistics, this.isIncome ? this.summary.income : this.summary.expense);
            })
            .onClick((event: ClickEvent) => {
              // 获取点击位置相对于画布的坐标
              const x = event.x - this.canvasSize / 2;
              const y = event.y - this.canvasSize / 2;
              
              const centerX = this.canvasSize / 2;
              const centerY = this.canvasSize / 2;
              const radius = this.canvasSize * 0.4;
              
              // 计算距离中心点的距离
              const distance = Math.sqrt(x * x + y * y);
              
              // 判断是否点击在扇形区域内
              if (distance < radius && distance > radius * 0.6) {
                // 计算点击位置的角度
                let angle = Math.atan2(y, x);
                if (angle < 0) {
                  angle += Math.PI * 2;
                }
                
                // 查找点击的是哪个扇形
                for (let i = 0; i < this.sectors.length; i++) {
                  const sector = this.sectors[i];
                  if (angle >= sector.start && angle <= sector.end) {
                    this.selectedPieIndex = i;
                    this.drawPieChart(this.statistics, this.isIncome ? this.summary.income : this.summary.expense);
                    return;
                  }
                }
              } else {
                // 点击中心区域或外部区域，取消选择
                this.selectedPieIndex = -1;
                this.drawPieChart(this.statistics, this.isIncome ? this.summary.income : this.summary.expense);
              }
            })
        }
        .width('100%')
        .height(BookingConstants.DEFAULT_CHART_HEIGHT)
        .alignContent(Alignment.Center)
      }
      .width('100%')
      .height(BookingConstants.DEFAULT_CHART_HEIGHT)
      .backgroundColor(Color.White)
      .borderRadius(8)
      .margin({ left: 16, right: 16, bottom: 16 })
    }
  }
  
  @Builder
  CategoryListItem(item: CategoryStatistic) {
    Row() {
      Row() {
        // 获取并显示分类图标
        Image(this.getCategoryIcon(item.icon))
          .width(40)
          .height(40)
          .margin({ right: 12 })
        
        Column() {
          // 显示分类名称
          Text(item.categoryName)
            .fontSize(16)
            .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
            .fontColor(BookingConstants.TEXT_PRIMARY_COLOR)
          
          // 显示百分比
          Row() {
            Text(`${this.calculatePercentage(item.amount, this.isIncome ? this.summary.income : this.summary.expense)}%`)
              .fontSize(14)
              .fontColor(BookingConstants.TEXT_HINT_COLOR)
          }
          .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      
      // 显示金额
      Column() {
        Text(`¥${item.amount.toFixed(2)}`)
          .fontSize(16)
          .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
          .fontColor(this.isIncome ? BookingConstants.SUCCESS_COLOR : BookingConstants.ERROR_COLOR)
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .backgroundColor(this.selectedPieIndex >= 0 && this.statistics[this.selectedPieIndex]?.categoryId === item.categoryId ? 
      '#F5F5F5' : Color.White) // 高亮显示选中的分类
    .borderRadius(4)
    .onClick(() => {
      // 找到当前点击项的索引
      for (let i = 0; i < this.statistics.length; i++) {
        if (this.statistics[i].categoryId === item.categoryId) {
          // 如果当前已经选中，则取消选中
          this.selectedPieIndex = this.selectedPieIndex === i ? -1 : i;
          this.drawPieChart(this.statistics, this.isIncome ? this.summary.income : this.summary.expense);
          break;
        }
      }
    })
  }
  
  /**
   * 获取分类图标资源
   * @param iconKey 图标标识符
   * @returns 图标资源
   */
  getCategoryIcon(icon: string): Resource {
    switch (icon) {
      case BookingConstants.ICON_SALARY:
        return $r('app.media.ic_salary' + BookingConstants.CARTOON_SUFFIX);
      case BookingConstants.ICON_BONUS:
        return $r('app.media.ic_bonus' + BookingConstants.CARTOON_SUFFIX);
      case BookingConstants.ICON_PARTTIME:
        return $r('app.media.ic_parttime' + BookingConstants.CARTOON_SUFFIX);
      case BookingConstants.ICON_INVESTMENT:
        return $r('app.media.ic_investment' + BookingConstants.CARTOON_SUFFIX);
      case BookingConstants.ICON_FOOD:
        return $r('app.media.ic_food' + BookingConstants.CARTOON_SUFFIX);
      case BookingConstants.ICON_TRANSPORT:
        return $r('app.media.ic_transport' + BookingConstants.CARTOON_SUFFIX);
      case BookingConstants.ICON_SHOPPING:
        return $r('app.media.ic_shopping' + BookingConstants.CARTOON_SUFFIX);
      case BookingConstants.ICON_MEDICAL:
        return $r('app.media.ic_medical' + BookingConstants.CARTOON_SUFFIX);
      case BookingConstants.ICON_HOUSING:
        return $r('app.media.ic_housing' + BookingConstants.CARTOON_SUFFIX);
      case BookingConstants.ICON_EDUCATION:
        return $r('app.media.ic_education' + BookingConstants.CARTOON_SUFFIX);
      case BookingConstants.ICON_MISC:
      default:
        return $r('app.media.ic_misc' + BookingConstants.CARTOON_SUFFIX);
    }
  }
  
  drawPieChart(stats: CategoryStatistic[], total: number) {
    if (!stats || stats.length === 0 || total <= 0 || !this.context) {
      return;
    }

    const centerX = this.canvasSize / 2;
    const centerY = this.canvasSize / 2;
    const radius = this.canvasSize * 0.4;
    
    let startAngle = 0;
    let endAngle = 0;
    
    // 清空画布
    this.context.clearRect(0, 0, this.canvasSize, this.canvasSize);
    
    // 清空之前的扇形信息
    this.sectors = [];
    
    // 绘制每个扇形
    stats.forEach((item, index) => {
      // 跳过金额为0的项
      if (item.amount <= 0) {
        return;
      }
      
      // 计算扇形角度
      const percentage = item.amount / total;
      endAngle = startAngle + percentage * Math.PI * 2;
      
      // 保存扇形信息
      const centerAngle = startAngle + (endAngle - startAngle) / 2;
      this.sectors.push({
        start: startAngle,
        end: endAngle,
        centerAngle: centerAngle,
        category: item
      });
      
      // 设置填充颜色
      const colorIndex = index % this.colors.length;
      this.context.fillStyle = this.colors[colorIndex];
      
      // 绘制扇形
      this.context.beginPath();
      this.context.moveTo(centerX, centerY);
      this.context.arc(centerX, centerY, radius, startAngle, endAngle);
      this.context.closePath();
      this.context.fill();
      
      // 如果是选中的扇形，绘制一个小的突出效果
      if (index === this.selectedPieIndex) {
        // 计算偏移方向
        const offsetX = Math.cos(centerAngle) * 10;
        const offsetY = Math.sin(centerAngle) * 10;
        
        // 绘制突出的扇形
        this.context.beginPath();
        this.context.moveTo(centerX + offsetX * 0.3, centerY + offsetY * 0.3);
        this.context.arc(centerX + offsetX * 0.3, centerY + offsetY * 0.3, radius + 5, startAngle, endAngle);
        this.context.closePath();
        this.context.fill();
      }
      
      // 更新起始角度
      startAngle = endAngle;
    });
    
    // 绘制中心白色圆形，形成环形图效果
    this.context.fillStyle = '#FFFFFF';
    this.context.beginPath();
    this.context.arc(centerX, centerY, radius * 0.6, 0, Math.PI * 2);
    this.context.closePath();
    this.context.fill();
    
    // 在中心显示当前选中分类信息
    if (this.selectedPieIndex >= 0 && this.selectedPieIndex < this.sectors.length) {
      const selectedSector = this.sectors[this.selectedPieIndex];
      const category = selectedSector.category;
      
      // 添加白色背景提升可读性
      this.context.fillStyle = 'rgba(255, 255, 255, 0.9)';
      this.context.beginPath();
      this.context.arc(centerX, centerY, radius * 0.55, 0, Math.PI * 2);
      this.context.closePath();
      this.context.fill();
      
      // 显示分类名称
      this.context.fillStyle = this.colors[this.selectedPieIndex % this.colors.length];
      this.context.font = 'bold 22px sans-serif'; // 显著增大字体
      this.context.textAlign = 'center';
      this.context.textBaseline = 'middle';
      this.context.fillText(category.categoryName, centerX, centerY - 25);
      
      // 显示金额
      this.context.font = 'bold 20px sans-serif'; // 显著增大字体
      this.context.fillText(
        `¥${category.amount.toFixed(2)}`, 
        centerX, 
        centerY + 10
      );
      
      // 显示百分比
      this.context.font = 'bold 20px sans-serif'; // 显著增大字体
      this.context.fillText(
        `${(category.amount / total * 100).toFixed(1)}%`, 
        centerX, 
        centerY + 40
      );
    } else if (stats.length > 0) {
      // 未选中任何分类时，显示提示信息
      this.context.fillStyle = 'rgba(255, 255, 255, 0.9)';
      this.context.beginPath();
      this.context.arc(centerX, centerY, radius * 0.55, 0, Math.PI * 2);
      this.context.closePath();
      this.context.fill();
      
      this.context.fillStyle = BookingConstants.TEXT_PRIMARY_COLOR;
      this.context.font = 'bold 20px sans-serif'; // 显著增大字体
      this.context.textAlign = 'center';
      this.context.textBaseline = 'middle';
      this.context.fillText('点击扇形查看详情', centerX, centerY);
    }
  }
  
  /**
   * 计算百分比
   * @param amount 金额
   * @param total 总金额
   * @returns 百分比字符串
   */
  calculatePercentage(amount: number, total: number): string {
    if (total <= 0 || amount <= 0) {
      return '0.0';
    }
    return (amount / total * 100).toFixed(1);
  }
}
