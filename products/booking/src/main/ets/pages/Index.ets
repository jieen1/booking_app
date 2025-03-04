import { router } from '@kit.ArkUI';
import { BookingConstants } from '../constants/BookingConstants';

/**
 * 应用入口页面，直接跳转到记账本页面
 */
@Entry
@Component
struct Index {
  aboutToAppear() {
    // 页面加载完成后直接跳转到记账本页面
    setTimeout(() => {
      router.replaceUrl({
        url: BookingConstants.ACCOUNT_BOOK_ROUTE
      });
    }, 500); // 短暂延迟确保页面已完全加载
  }

  build() {
    Column() {
      // 加载中的过渡界面
      LoadingProgress()
        .width(50)
        .height(50)
      
      Text('正在加载...')
        .fontSize(16)
        .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.BG_COLOR'))
  }
}