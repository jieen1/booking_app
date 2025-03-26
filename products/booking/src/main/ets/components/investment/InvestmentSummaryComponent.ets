/**
 * 投资汇总组件
 * 显示总资产、总收益和收益率等信息
 */

@Component
export struct InvestmentSummaryComponent {
  @Prop totalAssets: number = 0;
  @Prop totalProfit: number = 0;
  @Prop totalProfitRate: number = 0;
  
  // 添加事件回调属性
  onBuyClick?: () => void;
  onSellClick?: () => void;
  onTransferClick?: () => void;
  onMarketQuoteClick?: () => void; // 添加行情录入回调

  build() {
    Column() {
      // 总资产
      Row() {
        Text('总资产(元)')
          .fontSize(14)
          .fontColor('#666666')
        
        Blank()
        
        Text('总收益')
          .fontSize(14)
          .fontColor('#666666')
      }
      .width('100%')
      .padding({ top: 16, bottom: 8 })
      
      // 金额和收益率
      Row() {
        Text(`${this.totalAssets.toFixed(2)}`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        
        Blank()
        
        Column() {
          Text(`${this.totalProfit >= 0 ? '+' : ''}${this.totalProfit.toFixed(2)}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.totalProfit >= 0 ? '#ff5722' : '#4caf50')
          
          Text(`${this.totalProfitRate >= 0 ? '+' : ''}${this.totalProfitRate.toFixed(2)}%`)
            .fontSize(14)
            .fontColor(this.totalProfitRate >= 0 ? '#ff5722' : '#4caf50')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .padding({ bottom: 16 })
      
      // 分割线
      Divider()
        .color('#eeeeee')
        .width('100%')
        .margin({ top: 8, bottom: 8 })
      
      // 常用快捷操作
      Row() {
        Button({ type: ButtonType.Capsule }) {
          Row() {
            Text('买入')
              .fontSize(14)
              .fontColor('#ffffff')
          }
        }
        .backgroundColor('#ff9800')
        .height(36)
        .width(50)
        .margin({ right: 6 })
        .onClick(() => {
          if (this.onBuyClick) {
            this.onBuyClick();
          }
        })
        .animation({
          duration: 200,
          curve: Curve.EaseOut,
          iterations: 1,
          playMode: PlayMode.Normal
        })
        
        Button({ type: ButtonType.Capsule }) {
          Row() {
            Text('卖出')
              .fontSize(14)
              .fontColor('#ffffff')
          }
        }
        .backgroundColor('#4caf50')
        .height(36)
        .width(50)
        .margin({ right: 6 })
        .onClick(() => {
          if (this.onSellClick) {
            this.onSellClick();
          }
        })
        .animation({
          duration: 200,
          curve: Curve.EaseOut,
          iterations: 1,
          playMode: PlayMode.Normal
        })
        
        Button({ type: ButtonType.Capsule }) {
          Row() {
            Text('转账')
              .fontSize(14)
              .fontColor('#ffffff')
          }
        }
        .backgroundColor('#2196f3')
        .height(36)
        .width(50)
        .margin({ right: 6 }) // 添加右边距
        .onClick(() => {
          if (this.onTransferClick) {
            this.onTransferClick();
          }
        })
        .animation({
          duration: 200,
          curve: Curve.EaseOut,
          iterations: 1,
          playMode: PlayMode.Normal
        })
        
        // 添加行情录入按钮
        Button({ type: ButtonType.Capsule }) {
          Row() {
            Text('行情')
              .fontSize(14)
              .fontColor('#ffffff')
          }
        }
        .backgroundColor('#9c27b0')
        .height(36)
        .width(50)
        .onClick(() => {
          if (this.onMarketQuoteClick) {
            this.onMarketQuoteClick();
          }
        })
        .animation({
          duration: 200,
          curve: Curve.EaseOut,
          iterations: 1,
          playMode: PlayMode.Normal
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .padding({ top: 8, bottom: 8 })
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
