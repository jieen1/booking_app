import { BookingConstants } from '../constants/BookingConstants';
import { ThemeManager } from '../utils/ThemeManager';

/**
 * 主题切换开关组件
 */
@Component
export struct ThemeSwitch {
  @State isDark: boolean = false;
  
  // 回调ID，用于取消注册
  private callbackId: number = -1;
  
  aboutToAppear() {
    // 初始化主题状态
    this.isDark = ThemeManager.getInstance().isDarkTheme();
    
    // 注册主题变化回调，以便在其他地方切换主题时更新UI
    this.callbackId = ThemeManager.getInstance().registerThemeChangeCallback((theme: string) => {
      this.isDark = theme === BookingConstants.THEME_DARK;
    });
  }
  
  aboutToDisappear() {
    // 取消注册回调
    if (this.callbackId >= 0) {
      ThemeManager.getInstance().unregisterThemeChangeCallback(this.callbackId);
    }
  }
  
  /**
   * 切换主题
   */
  switchTheme() {
    const newTheme = this.isDark ? BookingConstants.THEME_LIGHT : BookingConstants.THEME_DARK;
    ThemeManager.getInstance().switchTheme(newTheme);
  }
  
  build() {
    Row() {
      Text(this.isDark ? '深色' : '浅色')
        .fontSize(14)
        .fontColor(BookingConstants.TEXT_SECONDARY_COLOR)
        .margin({ right: 8 })
      
      Toggle({ type: ToggleType.Switch, isOn: this.isDark })
        .width(40)
        .height(20)
        .selectedColor(BookingConstants.PRIMARY_COLOR)
        .onChange((isOn: boolean) => {
          this.isDark = isOn;
          this.switchTheme();
        })
    }
    .width('auto')
    .height(40)
    .borderRadius(20)
    .backgroundColor(this.isDark ? BookingConstants.DARK_CARD_BG_COLOR : BookingConstants.LIGHT_PRIMARY_LIGHT_COLOR)
    .padding({ left: 12, right: 12 })
  }
}
