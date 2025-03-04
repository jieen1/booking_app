import { BookingConstants } from '../constants/BookingConstants';
import { router } from '@kit.ArkUI';

/**
 * 我的页面
 */
interface MenuItem {
  title: string;
  icon: Resource;
  route?: string;
  onClick?: () => void;
}

@Entry
@Component
struct Mine {
  @State userName: string = '用户名';
  @State userAvatar: Resource = $r('app.media.ic_user_cartoon_new'); 
  @State themeCallbackId: number = -1;
  
  private menuItems: Array<MenuItem> = [
    {
      title: '我的账单',
      icon: $r('app.media.ic_statistics_cartoon_new'),
      route: BookingConstants.STATISTICS_ROUTE
    },
    {
      title: '预算设置',
      icon: $r('app.media.ic_budget_cartoon_new'),
      route: ''
    },
    {
      title: '个人信息',
      icon: $r('app.media.ic_user_cartoon_new'),
      route: ''
    },
    {
      title: '设置',
      icon: $r('app.media.ic_settings_cartoon_new'),
      route: ''
    },
    {
      title: '关于',
      icon: $r('app.media.ic_about_cartoon_new'),
      route: ''
    }
  ];
  
  build() {
    Column() {
      // 用户信息区域
      Row() {
        Image(this.userAvatar)
          .width(80)
          .height(80)
          .borderRadius(40)
          .margin({ right: 16 })
        
        Column() {
          Text(this.userName)
            .fontSize(18)
            .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
            .fontColor(BookingConstants.TEXT_PRIMARY_COLOR)
          
          Text('开启你的记账之旅')
            .fontSize(14)
            .fontColor(BookingConstants.TEXT_SECONDARY_COLOR)
            .margin({ top: 8 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .height('30%')
      .padding(16)
      .backgroundColor(Color.White)
      .borderRadius(10)
      .margin({ top: 16, left: 16, right: 16 })
      
      // 菜单列表
      Column() {
        List() {
          ForEach(this.menuItems, (item: MenuItem) => {
            ListItem() {
              Row() {
                Row() {
                  Image(item.icon)
                    .width(24)
                    .height(24)
                    .margin({ right: 12 })
                  
                  Text(item.title)
                    .fontSize(16)
                    .fontColor(BookingConstants.TEXT_PRIMARY_COLOR)
                }
                
                Image($r('app.media.ic_right_cartoon_new'))
                  .width(20)
                  .height(20)
                  .fillColor(BookingConstants.TEXT_HINT_COLOR)
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .padding({ top: 16, bottom: 16 })
            }
            .onClick(() => {
              if (item.onClick) {
                item.onClick();
              } else if (item.route && item.route.length > 0) {
                router.pushUrl({
                  url: item.route
                });
              }
            })
          })
        }
        .width('100%')
        .divider({
          strokeWidth: 0.5,
          color: BookingConstants.BORDER_COLOR,
          startMargin: 52,
          endMargin: 16
        })
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius(10)
      .margin({ top: 16, left: 16, right: 16 })
      
      // 底部版本信息
      Column() {
        Text('版本 1.0.0')
          .fontSize(14)
          .fontColor(BookingConstants.TEXT_HINT_COLOR)
          .margin({ top: 32 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .layoutWeight(1)
      .justifyContent(FlexAlign.End)
      .padding({ bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BookingConstants.MINT_BG_COLOR_WHITE)
  }
}
