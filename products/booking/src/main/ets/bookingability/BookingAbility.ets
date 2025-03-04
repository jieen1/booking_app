import UIAbility from '@ohos.app.ability.UIAbility';
import { window, display } from '@kit.ArkUI'
import hilog from '@ohos.hilog';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';

export default class BookingAbility extends UIAbility {
  private windowObj?: window.Window
  private curBp: string = ''

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    hilog.info(0x0000, 'testTag', '%{public}s', 'BookingAbility onCreate');
  }

  async onDestroy() {
    hilog.info(0x0000, 'testTag', '%{public}s', 'BookingAbility onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage) {
    hilog.info(0x0000, 'testTag', '%{public}s', 'BookingAbility onWindowStageCreate');

    windowStage.getMainWindow().then((windowObj) => {
      this.windowObj = windowObj
      // 获取应用启动时的窗口尺寸
      this.updateBreakpoint(windowObj.getWindowProperties().windowRect.width)
      // 注册回调函数，监听窗口尺寸变化
      windowObj.on('windowSizeChange', (windowSize)=>{
        this.updateBreakpoint(windowSize.width)
      })
    });
    
    // 获取当前窗口并禁用左滑返回手势
    let windowClass = await windowStage.getMainWindow();
    try {
      await windowClass.setWindowSystemBarEnable(['status']);
      windowClass.setWindowLayoutFullScreen(true);
      // 设置窗口手势识别模式，禁用边缘手势
      await windowClass.setWindowTouchable(true);
      windowClass.on('windowEvent', (data) => {
        hilog.info(0x0000, 'testTag', 'Received window event. Data: %{public}s', JSON.stringify(data) ?? '');
      });
    } catch (err) {
      hilog.error(0x0000, 'testTag', 'Failed to configure window. Cause: %{public}s', JSON.stringify(err) ?? '');
    }
    
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
    });
  }

  async onWindowStageDestroy() {
    hilog.info(0x0000, 'testTag', '%{public}s', 'BookingAbility onWindowStageDestroy');
  }

  async onForeground() {
    hilog.info(0x0000, 'testTag', '%{public}s', 'BookingAbility onForeground');
  }

  async onBackground() {
    hilog.info(0x0000, 'testTag', '%{public}s', 'BookingAbility onBackground');
  }

  private updateBreakpoint(windowWidth: number) :void{
    // 拿到当前窗口对象获取当前所在displayId
    let displayId: number | undefined = this.windowObj?.getWindowProperties().displayId
    try {
      // 将长度的单位由px换算为vp
      let windowWidthVp = windowWidth / display.getDisplayByIdSync(displayId).densityPixels
      let newBp: string = ''
      if (windowWidthVp < 320) {
        newBp = 'xs'
      } else if (windowWidthVp < 600) {
        newBp = 'sm'
      } else if (windowWidthVp < 840) {
        newBp = 'md'
      } else {
        newBp = 'lg'
      }
      if (this.curBp !== newBp) {
        this.curBp = newBp
        // 使用状态变量记录当前断点值
        AppStorage.setOrCreate('currentBreakpoint', this.curBp)
      }
    } catch(err) {
      console.log("getDisplayByIdSync failed err"+err.code)
    }
  }
}