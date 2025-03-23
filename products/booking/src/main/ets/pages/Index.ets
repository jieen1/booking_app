import { CommonConstants } from '../constants/CommonConstants';
import HomePage from '../pages/HomePage';
import AccountBook from '../pages/AccountBook';
import AddRecord from '../pages/AddRecord';
import Statistics from '../pages/Statistics';
import Mine from '../pages/Mine';
import { InvestmentOverviewPage } from '../pages/InvestmentOverviewPage';

/**
 * 应用入口页面
 */
@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  @StorageLink('mainBreakpoint') currentBreakpoint: string = CommonConstants.BREAKPOINTS_INITIALIZE_NAME;
  private pathStack: NavPathStack = new NavPathStack();

  @Builder
  CustomBottomBar() {
    Row() {
      ForEach([0, 1, 2, 3, 4, 5], (index: number) => {
        Column() {
          if (index === 0) {
            this.TabBuilder(index, $r('app.string.tab_bar1'), $r('app.media.ic_home'), $r('app.media.ic_home_active'));
          } else if (index === 1) {
            this.TabBuilder(index, $r('app.string.tab_bar2'), $r('app.media.ic_bill'), $r('app.media.ic_bill_active'));
          } else if (index === 2) {
            this.TabBuilder(index, $r('app.string.tab_bar3'), $r('app.media.ic_add'), $r('app.media.ic_add_active'));
          } else if (index === 3) {
            this.TabBuilder(index, $r('app.string.tab_bar4'), $r('app.media.ic_statistics'), $r('app.media.ic_statistics_active'));
          } else if (index === 4) {
            this.TabBuilder(index, $r('app.string.tab_bar5'), $r('app.media.ic_profile'), $r('app.media.ic_profile_active'));
          } else if (index === 5) {
            this.TabBuilder(index, $r('app.string.tab_bar6'), $r('app.media.ic_investment'), $r('app.media.ic_investment_active'));
          }
        }
        .width(60)
        .height(56)
        .backgroundColor($r('app.color.BG_COLOR_TAB'))
        .onClick(() => {
          this.currentIndex = index;
        })
      })
    }
    .width('100%')
    .height(80)
    .justifyContent(FlexAlign.SpaceAround)
    .backgroundColor($r('app.color.BG_COLOR_TAB'))
    .padding({bottom: 20})
  }

  @Builder
  TabBuilder(index: number, title: Resource, icon: Resource, iconSelected: Resource) {
    Column() {
      Image(this.currentIndex === index ? iconSelected : icon)
        .width(24)
        .height(24)
        .margin(5)
        .objectFit(ImageFit.Contain);
      Text(title)
        .fontColor(this.currentIndex === index ? $r('app.color.TEXT_PRIMARY_COLOR') : $r('app.color.TEXT_SECONDARY_COLOR'))
        .fontSize(12)
        .fontWeight(500);
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }

  aboutToAppear() {
    // 全局设置 NavPathStack 以便子页面使用
    AppStorage.setOrCreate('PathStack', this.pathStack);
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.Bottom }) {
        // 内容区域
        Navigation(this.pathStack) {
          NavDestination() {
            if (this.currentIndex === 0) {
              HomePage();
            } else if (this.currentIndex === 1) {
              AccountBook();
            } else if (this.currentIndex === 2) {
              AddRecord();
            } else if (this.currentIndex === 3) {
              Statistics();
            } else if (this.currentIndex === 4) {
              Mine();
            } else if (this.currentIndex === 5) {
              InvestmentOverviewPage();
            }
          }
          .hideTitleBar(true)
        }
        .hideTitleBar(true)
        .mode(NavigationMode.Stack)
        .width('100%')
        .height('100%')
        
        // 自定义底部导航栏
        Column() {
          this.CustomBottomBar();
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')

    }
    .backgroundColor($r('app.color.BG_COLOR_TAB'))
    .width('100%')
    .height('100%')
  }
}