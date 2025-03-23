/**
 * u81eau5b9au4e49u9009u62e9u5bf9u8bddu6846u7ec4u4ef6
 * u7528u4e8eu663eu793au5c5eu6027u9009u62e9u5217u8868
 */
import { BookingConstants } from '../constants/BookingConstants';

/**
 * u9009u9879u5b9au4e49u63a5u53e3
 */
export interface SelectOption {
  value: string;
  text: string;
}

/**
 * u9009u62e9u5bf9u8bddu6846u53c2u6570u63a5u53e3
 */
export interface SelectionDialogParams {
  options: SelectOption[];
  title?: string;
  onSelect: (value: string) => void;
  onCancel?: () => void;
}

/**
 * u9009u62e9u5bf9u8bddu6846u7ec4u4ef6
 */
@CustomDialog
export struct SelectionDialog {
  // u5bf9u8bddu6846u63a7u5236u5668
  controller: CustomDialogController;
  // u6807u9898
  title: string = '';
  // u5bf9u8bddu6846u6570u636e
  options: SelectOption[] = [];
  // u9009u62e9u56deu8c03
  onSelect: (value: string) => void = () => {};
  // u53d6u6d88u56deu8c03
  onCancel: () => void = () => {};

  build() {
    Column() {
      // u6807u9898
      if (this.title) {
        Text(this.title)
          .fontSize(18)
          .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
          .margin({ top: 20, bottom: 10 })
          .width('90%')
          .textAlign(TextAlign.Center)
      }
      
      // u5217u8868u663eu793a
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
      
      // u53d6u6d88u6309u94ae
      Button('\u53d6\u6d88')
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
   * u521bu5efau9009u62e9u6846
   * @param params u9009u62e9u6846u53c2u6570
   * @returns CustomDialogController
   */
  static create(params: SelectionDialogParams): CustomDialogController {
    const dialogController = new CustomDialogController({
      builder: SelectionDialog({
        title: params.title || 'u8bf7u9009u62e9',
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
   * u663eu793au9009u62e9u6846
   * @param params u9009u62e9u6846u53c2u6570
   */
  static show(params: SelectionDialogParams): void {
    const dialogController = SelectionDialog.create(params);
    dialogController.open();
  }
}
