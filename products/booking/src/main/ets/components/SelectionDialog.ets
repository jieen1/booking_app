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
 * 选择对话框参数接口
 */
export interface SelectionDialogParams {
  options: SelectOption[];
  title?: string;
  onSelect: (value: string) => void;
  onCancel?: () => void;
}

/**
 * 选择对话框组件
 */
@CustomDialog
export struct SelectionDialog {
  // 对话框控制器
  controller: CustomDialogController;
  // 标题
  title: string = '';
  // 对话框数据
  options: SelectOption[] = [];
  // 选择回调
  onSelect: (value: string) => void = () => {};
  // 取消回调
  onCancel: () => void = () => {};

  build() {
    Column() {
      // 标题
      if (this.title) {
        Text(this.title)
          .fontSize(18)
          .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
          .margin({ top: 20, bottom: 10 })
          .width('90%')
          .textAlign(TextAlign.Center)
      }
      
      // 列表显示
      Column() {
        ForEach(this.options, (option: SelectOption) => {
          Row() {
            Text(option.text)
              .fontSize(16)
              .padding(12)
              .width('100%')
              .fontColor('#333333')
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.onSelect(option.value);
                this.controller.close();
              })
          }
          .width('100%')
          Divider().width('90%').height(1).color('#EEEEEE')
        })
      }
      .width('100%')
      .padding({ top: 10, bottom: 10 })
      
      // 取消按钮
      Button('取消')
        .width('90%')
        .height(44)
        .fontSize(16)
        .fontColor('#333333')
        .backgroundColor('#F5F5F5')
        .margin({ top: 10, bottom: 16 })
        .onClick(() => {
          this.onCancel();
          this.controller.close();
        })
    }
    .width('90%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .padding({ top: 8, bottom: 0 })
  }

  /**
   * 创建选择框
   * @param params 选择框参数
   * @returns CustomDialogController
   */
  static create(params: SelectionDialogParams): CustomDialogController {
    const dialogController = new CustomDialogController({
      builder: SelectionDialog({
        title: params.title || '请选择',
        options: params.options,
        onSelect: params.onSelect,
        onCancel: params.onCancel || (() => {})
      }),
      cancel: params.onCancel,
      autoCancel: true
    });
    
    return dialogController;
  }

  /**
   * 显示选择框
   * @param params 选择框参数
   */
  static show(params: SelectionDialogParams): void {
    const dialogController = SelectionDialog.create(params);
    dialogController.open();
  }
}
