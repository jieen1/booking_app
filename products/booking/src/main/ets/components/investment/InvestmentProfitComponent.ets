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
  @State timeRanges: ProfitTimeRange[] = [
    { label: '今日', days: 1, active: true },
    { label: '本周', days: 7, active: false },
    { label: '本月', days: 30, active: false },
    { label: '今年', days: 365, active: false },
    { label: '全部', days: 0, active: false }
  ];

  calculateTotalValue() {
    let totalValue = 0;

    // 计算总资产
    for (const asset of this.assets) {
      totalValue += asset.getCurrentValue();
    }

    return totalValue;
  }

  getTotalCost() {
    let totalCost = 0;

    // 计算总成本
    for (const asset of this.assets) {
      totalCost += asset.getCost();
    }

    return totalCost;
  }

  getTotalProfit() {
    let totalProfit = 0;

    // 计算总收益
    for (const asset of this.assets) {
      totalProfit += asset.getProfit();
    }

    return totalProfit;
  }

  getProfitRate() {
    if (this.getTotalCost() === 0) {
      return 0;
    }

    return (this.getTotalProfit() / this.getTotalCost()) * 100;
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
          
          Text(this.calculateTotalValue().toFixed(2))
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
            Text(`${this.getTotalProfit() >= 0 ? '+' : ''}${this.getTotalProfit().toFixed(2)}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getTotalProfit() >= 0 ? '#ff5722' : '#4caf50')
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
          
          Text(this.getTotalCost().toFixed(2))
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
            Text(`${this.getProfitRate() >= 0 ? '+' : ''}${this.getProfitRate().toFixed(2)}%`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getProfitRate() >= 0 ? '#ff5722' : '#4caf50')
          }
          .margin({ top: 8 })
        }
        .alignItems(HorizontalAlign.End)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
      
      // 收益趋势略图 TODO
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
