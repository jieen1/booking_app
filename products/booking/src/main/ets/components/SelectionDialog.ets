/**
 * 自定义选择对话框组件
 * 用于显示属性选择列表
 */
import { BookingConstants } from '../constants/BookingConstants';

/**
 * 选项定义接口
 */
export interface SelectOption {
  value: string;
  text: string;
}

/**
 * 选择对话框组件
 */
@CustomDialog
export struct SelectionDialog {
  // 对话框控制器
  controller: CustomDialogController;
  // 标题
  title: string = '请选择';
  // 对话框数据
  options: SelectOption[] = [];
  // 选择回调
  onSelect: (value: string) => void = () => {
  };

  build() {
    Column() {
      // 标题
      if (this.title) {
        Row() {
          Text(this.title)
            .fontSize(18)
            .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
            .margin({ top: 10, bottom: 10 })
            .width('90%')
            .textAlign(TextAlign.Center)
            .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 16, bottom: 16 })
      }

      List() {
        ForEach(this.options, (option: SelectOption) => {
          ListItem() {
            Row() {
              Text(option.text)
                .fontSize(16)
                .padding(12)
                .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
                .layoutWeight(1)
            }
            .width('100%')
            .padding(16)
            .onClick(() => {
              this.onSelect(option.value);
            })
          }
        })
      }
      .divider({
        strokeWidth: 1,
        color: $r('app.color.BORDER_COLOR'),
        startMargin: 16,
        endMargin: 16
      })
      .layoutWeight(1)
    }
    .width('85%')
    .height(400)
    .backgroundColor($r('app.color.BG_COLOR'))
    .borderRadius(12)
    .padding({ top: 8, bottom: 0 })
  }
}
