import TabBarItem from '../common/TabBarItem';
import { CommonConstants } from '../constants/CommonConstants';
import HomePage from '../pages/HomePage';
import AccountBook from '../pages/AccountBook';
import AddRecord from '../pages/AddRecord';
import Statistics from '../pages/Statistics';
import Mine from '../pages/Mine';

/**
 * 应用入口页面，直接跳转到记账本页面
 */
@Entry
@Component
struct Index {
  @State currentIndex: number = 0
  @StorageLink('mainBreakpoint') currentBreakpoint: string = CommonConstants.BREAKPOINTS_INITIALIZE_NAME;
  private onTabChange = (index: number) => {
    this.currentIndex = index
  }

  aboutToAppear() {
  }

  @Builder
  tabItem(index: number, title: Resource, icon: Resource, iconSelected: Resource) {
    TabBarItem({
      index: index,
      currentIndex: this.currentIndex,
      title: title,
      icon: icon,
      iconSelected: iconSelected
    })
  }

  build() {
    // 设置TabBar在主轴方向起始或结尾位置
    Tabs({ barPosition: this.currentBreakpoint === "lg" ? BarPosition.Start : BarPosition.End }) {
      // 首页
      TabContent() {
        HomePage()
      }
      .tabBar(this.tabItem(0, $r('app.string.tab_bar1'), $r('app.media.ic_home'),
        $r('app.media.ic_home_active')))


      TabContent() {
        AccountBook()
      }.tabBar(this.tabItem(1, $r('app.string.tab_bar2'), $r('app.media.ic_bill'), $r('app.media.ic_bill_active')))

      TabContent() {
        AddRecord()
      }
      .tabBar(this.tabItem(2, $r('app.string.tab_bar3'), $r('app.media.ic_add'),
        $r('app.media.ic_add_active')))

      TabContent() {
        Statistics()
      }
      .tabBar(this.tabItem(3, $r('app.string.tab_bar4'), $r('app.media.ic_statistics'),
        $r('app.media.ic_statistics_active')))

      TabContent() {
        Mine()
      }
      .tabBar(this.tabItem(4, $r('app.string.tab_bar5'), $r('app.media.ic_profile'),
        $r('app.media.ic_profile_active')))
    }
    .backgroundColor($r('app.color.BG_COLOR_TAB'))
    .barMode(BarMode.Fixed)
    .barWidth(this.currentBreakpoint === "lg" ? 96 : '100%')
    .barHeight(this.currentBreakpoint === "lg" ? '60%' : 56)
    // 设置TabBar放置在水平或垂直方向
    .vertical(this.currentBreakpoint === "lg")
    .onChange(this.onTabChange)
    .padding({ bottom: 15 })
  }
}