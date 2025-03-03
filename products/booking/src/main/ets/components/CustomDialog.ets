import { BookingConstants } from '../constants/BookingConstants';


/**
 * 自定义对话框组件
 * 提供统一的对话框样式，确保应用风格一致性
 */
@CustomDialog
export struct CustomAlertDialog {
  // 对话框控制器
  controller: CustomDialogController;
  // 标题
  title: string = '';
  // 内容
  message: string = '';
  // 取消按钮文本
  cancelText: string = '取消';
  // 确认按钮文本
  confirmText: string = '确认';
  // 取消按钮回调
  onCancel?: () => void;
  // 确认按钮回调
  onConfirm?: () => void;

  build() {
    Column() {
      // 标题
      Text(this.title)
        .fontSize(18)
        .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
        .margin({ top: 24, bottom: 12 })
        .fontColor(BookingConstants.TEXT_PRIMARY_COLOR)
      
      // 消息内容
      Text(this.message)
        .fontSize(16)
        .fontColor(BookingConstants.TEXT_SECONDARY_COLOR)
        .margin({ bottom: 24 })
        .textAlign(TextAlign.Center)
        .padding({ left: 24, right: 24 })
      
      // 分隔线
      Divider()
        .width('100%')
        .height(1)
        .color('#E0E0E0')
      
      // 按钮容器
      Row() {
        // 取消按钮
        Button(this.cancelText)
          .fontSize(16)
          .fontColor(BookingConstants.TEXT_SECONDARY_COLOR)
          .backgroundColor(BookingConstants.BG_COLOR_WHITE)
          .width('50%')
          .height(48)
          .onClick(() => {
            if (this.onCancel) {
              this.onCancel();
            }
            this.controller.close();
          })
        
        // 按钮分隔线
        Divider()
          .width(1)
          .height(48)
          .vertical(true)
          .color('#E0E0E0')
        
        // 确认按钮
        Button(this.confirmText)
          .fontSize(16)
          .fontColor('#FF5722')  // 使用橙色作为强调色
          .backgroundColor(BookingConstants.BG_COLOR_WHITE)
          .width('50%')
          .height(48)
          .onClick(() => {
            if (this.onConfirm) {
              this.onConfirm();
            }
            this.controller.close();
          })
      }
      .width('100%')
      .height(48)
    }
    .width('80%')
    .backgroundColor(BookingConstants.BG_COLOR_WHITE)
    .borderRadius(12)
    .padding({ top: 8, bottom: 0 })
  }
}
