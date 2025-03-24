/**
 * 投资收益组件
 * 显示投资账本的收益信息及收益趋势
 */
import { InvestmentBookModel } from '../../model/InvestmentBookModel';
import { InvestmentAssetModel } from '../../model/InvestmentAssetModel';

interface ProfitTimeRange {
  label: string;
  days: number;
  active: boolean;
}

@Component
export struct InvestmentProfitComponent {
  @ObjectLink book: InvestmentBookModel;
  @Prop assets: InvestmentAssetModel[] = [];
  @State totalValue: number = 0;
  @State totalCost: number = 0;
  @State totalProfit: number = 0;
  @State profitRate: number = 0;
  @State timeRanges: ProfitTimeRange[] = [
    { label: '今日', days: 1, active: true },
    { label: '本周', days: 7, active: false },
    { label: '本月', days: 30, active: false },
    { label: '今年', days: 365, active: false },
    { label: '全部', days: 0, active: false }
  ];
  
  aboutToAppear() {
    this.calculateProfits();
  }
  
  calculateProfits() {
    let totalValue = 0;
    let totalCost = 0;
    
    // 计算总资产和总成本
    for (const asset of this.assets) {
      totalValue += asset.getCurrentValue();
      totalCost += asset.getCost();
    }
    
    this.totalValue = totalValue;
    this.totalCost = totalCost;
    this.totalProfit = totalValue - totalCost;
    this.profitRate = totalCost > 0 ? (this.totalProfit / totalCost) * 100 : 0;
  }
  
  switchTimeRange(index: number) {
    for (let i = 0; i < this.timeRanges.length; i++) {
      this.timeRanges[i].active = (i === index);
    }
    
    // 这里可以根据选择的时间范围加载不同的收益数据
    // 实际项目中可以实现从数据库获取不同时间段的收益数据
  }
  
  build() {
    Column() {
      // 收益时间范围选择
      Row() {
        ForEach(this.timeRanges, (item: ProfitTimeRange, index: number) => {
          Text(item.label)
            .fontSize(14)
            .fontColor(item.active ? '#4fc08d' : '#666666')
            .fontWeight(item.active ? FontWeight.Bold : FontWeight.Normal)
            .backgroundColor(item.active ? 'rgba(79, 192, 141, 0.1)' : 'transparent')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(16)
            .margin({ right: 8 })
            .onClick(() => {
              this.switchTimeRange(index);
            })
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .margin({ bottom: 16 })
      
      // 收益数据展示
      Row() {
        Column() {
          Text('总资产(元)')
            .fontSize(14)
            .fontColor('#666666')
          
          Text(this.totalValue.toFixed(2))
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ top: 8 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        
        Column() {
          Text('收益(元)')
            .fontSize(14)
            .fontColor('#666666')
          
          Row() {
            Text(`${this.totalProfit >= 0 ? '+' : ''}${this.totalProfit.toFixed(2)}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.totalProfit >= 0 ? '#ff5722' : '#4caf50')
          }
          .margin({ top: 8 })
        }
        .alignItems(HorizontalAlign.End)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
      
      // 收益率和市值
      Row() {
        Column() {
          Text('总市值(元)')
            .fontSize(14)
            .fontColor('#666666')
          
          Text(this.totalCost.toFixed(2))
            .fontSize(16)
            .fontColor('#333333')
            .margin({ top: 8 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        
        Column() {
          Text('收益率')
            .fontSize(14)
            .fontColor('#666666')
          
          Row() {
            Text(`${this.profitRate >= 0 ? '+' : ''}${this.profitRate.toFixed(2)}%`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.profitRate >= 0 ? '#ff5722' : '#4caf50')
          }
          .margin({ top: 8 })
        }
        .alignItems(HorizontalAlign.End)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
      
      // 收益趋势略图
      Row() {
        // 这里应该显示收益趋势图
        // 默认显示一个提示图形
        Column() {
          Text('收益趋势图开发中')
            .fontSize(14)
            .fontColor('#999999')
        }
        .width('100%')
        .height(120)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('rgba(0, 0, 0, 0.03)')
        .borderRadius(8)
      }
      .width('100%')
      .margin({ top: 16 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    // 添加毛玻璃效果
    .backgroundBlurStyle(BlurStyle.Thin)
    .borderWidth(1)
    .borderColor('#eeeeee')
  }
}
