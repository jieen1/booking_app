import UIAbility from '@ohos.app.ability.UIAbility';
import Window from '@ohos.window';
import hilog from '@ohos.hilog';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';

export default class BookingAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    hilog.info(0x0000, 'testTag', '%{public}s', 'BookingAbility onCreate');
  }

  async onDestroy() {
    hilog.info(0x0000, 'testTag', '%{public}s', 'BookingAbility onDestroy');
  }

  async onWindowStageCreate(windowStage: Window.WindowStage) {
    hilog.info(0x0000, 'testTag', '%{public}s', 'BookingAbility onWindowStageCreate');
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
}