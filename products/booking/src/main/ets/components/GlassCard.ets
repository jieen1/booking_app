import { BookingConstants } from '../constants/BookingConstants';

/**
 * 毛玻璃效果卡片组件
 */
@Component
export struct GlassCard {
  // 卡片标题，可选
  title?: ResourceStr;
  
  // 子组件
  @BuilderParam content: () => void;
  
  // 额外样式属性
  borderRadius: number = 16;
  padding: number | Padding = 16;
  margin: Margin | Length = 0;
  
  build() {
    Column() {
      if (this.title) {
        Text(this.title)
          .fontSize(18)
          .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
          .fontColor(BookingConstants.TEXT_PRIMARY_COLOR)
          .margin({ bottom: 16 })
      }
      
      this.content()
    }
    .width('100%')
    .padding(this.padding)
    .margin(this.margin)
    .borderRadius(this.borderRadius)
    .backdropBlur(20) // 启用背景模糊效果
    .backgroundColor(new Color(BookingConstants.CARD_BG_COLOR).alpha(0.8)) // 半透明背景
    .border({ width: 1, color: new Color('#FFFFFF').alpha(0.15) }) // 微妙的边框
    .shadow({ radius: 8, color: new Color('#000000').alpha(0.08), offsetY: 4 }) // 柔和阴影
  }
}
