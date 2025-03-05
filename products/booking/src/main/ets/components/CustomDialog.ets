import { BookingConstants } from '../constants/BookingConstants';
import { CategoryModel } from '../model/CategoryModel';
import { DBHelper } from '../database/DBHelper';
import { IconUtils } from '../utils/IconUtils';

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
        .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
      
      // 消息内容
      Text(this.message)
        .fontSize(16)
        .fontColor($r('app.color.TEXT_SECONDARY_COLOR'))
        .margin({ bottom: 24 })
        .textAlign(TextAlign.Center)
        .padding({ left: 24, right: 24 })
      
      // 分隔线
      Divider()
        .width('100%')
        .height(1)
        .color($r('sys.color.ohos_id_color_list_separator'))
      
      // 按钮容器
      Row() {
        // 取消按钮
        Button(this.cancelText)
          .fontSize(16)
          .fontColor($r('app.color.TEXT_SECONDARY_COLOR'))
          .backgroundColor($r('app.color.BG_COLOR'))
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
          .color($r('sys.color.ohos_id_color_list_separator'))
        
        // 确认按钮
        Button(this.confirmText)
          .fontSize(16)
          .fontColor($r('app.color.WARNING_COLOR'))
          .backgroundColor($r('app.color.BG_COLOR'))
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
    .backgroundColor($r('app.color.BG_COLOR'))
    .borderRadius(12)
    .padding({ top: 8, bottom: 0 })
  }
}

/**
 * 自定义编辑对话框组件
 * 用于记录的编辑功能
 */
@CustomDialog
export struct EditRecordDialog {
  // 对话框控制器
  controller: CustomDialogController;
  // 金额
  @Link editAmount: string;
  // 描述
  @Link editDescription: string;
  // 当前选中的分类ID
  @Link selectedCategoryId: number;
  // 分类列表
  private categories: CategoryModel[] = [];
  // 当前记录类型（收入/支出）
  @Link recordType: number;
  // 确认回调
  onConfirm?: () => void;
  // 取消回调
  onCancel?: () => void;

  async aboutToAppear() {
    // 加载分类列表
    await this.loadCategories();
  }

  async loadCategories() {
    try {
      if (await DBHelper.getInstance().initDatabase()) {
        this.categories = await DBHelper.getInstance().getAllCategories();
      } else {
        throw new Error("获取分类信息失败！");
      }
    } catch (error) {
      console.error('加载分类失败:', error);
    }
  }

  build() {
    Column() {
      // 标题栏
      Text('编辑记录')
        .fontSize(18)
        .fontWeight(BookingConstants.FONT_WEIGHT_MEDIUM)
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 24, bottom: 16 })
        .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
      
      // 金额输入
      Column() {
        Text('金额')
          .fontSize(16)
          .fontColor($r('app.color.TEXT_SECONDARY_COLOR'))
          .width('100%')
          .margin({ bottom: 8 })
          
        TextInput({ text: this.editAmount, placeholder: '请输入金额' })
          .type(InputType.NUMBER_DECIMAL)
          .fontSize(16)
          .placeholderFont({ size: 16 })
          .padding(12)
          .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
          .placeholderColor($r('app.color.TEXT_SECONDARY_COLOR'))
          .border({
            width: 1,
            color: $r('app.color.BORDER_COLOR'),
            radius: 8
          })
          .backgroundColor($r('app.color.BG_COLOR'))
          .width('100%')
          .maxLength(14)
          .height(48)
          .onChange((value: string) => {
            this.editAmount = value;
          })
      }
      .width('90%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 16 })
      
      // 描述输入
      Column() {
        Text('描述')
          .fontSize(16)
          .fontColor($r('app.color.TEXT_SECONDARY_COLOR'))
          .width('100%')
          .margin({ bottom: 8 })
          
        TextInput({ text: this.editDescription, placeholder: '请输入描述（可选）' })
          .fontSize(16)
          .placeholderFont({ size: 16 })
          .padding(12)
          .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
          .placeholderColor($r('app.color.TEXT_SECONDARY_COLOR'))
          .border({
            width: 1,
            color: $r('app.color.BORDER_COLOR'),
            radius: 8
          })
          .backgroundColor($r('app.color.BG_COLOR'))
          .width('100%')
          .height(48)
          .onChange((value: string) => {
            this.editDescription = value;
          })
      }
      .width('90%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 16 })
      
      // 分类选择
      Column() {
        Text('分类')
          .fontSize(16)
          .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
          .width('100%')
          .margin({ bottom: 8 })
          
        // 分类列表
        Scroll() {
          Row() {
            ForEach(this.categories.filter(category => category.type === this.recordType), 
              (category: CategoryModel) => {
                Column() {
                  Image(IconUtils.getCategoryIcon(category.icon))
                    .width(36)
                    .height(36)
                    .margin({ bottom: 4 })
                  
                  Text(category.name)
                    .fontSize(12)
                    .fontColor(this.selectedCategoryId === category.id ?
                    $r('app.color.TEXT_HINT_COLOR') : $r('app.color.TEXT_SECONDARY_COLOR'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width(56)
                .height(68)
                .margin(4)
                .padding(4)
                .borderRadius(8)
                .backgroundColor(this.selectedCategoryId === category.id ?
                $r('app.color.BG_COLOR_SECONDARY') : Color.Transparent)
                .border({
                  width: this.selectedCategoryId === category.id ? 1 : 0,
                  color: $r('app.color.BORDER_COLOR')
                })
                .onClick(() => {
                  if (category.id) {
                    this.selectedCategoryId = category.id;
                  }
                })
            })
          }
          .width('100%')
          .padding(8)
        }
        .width('100%')
        .height(90)
        .scrollBar(BarState.Off)
      }
      .width('90%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 16 })
       
      // 分隔线
      Divider()
        .width('100%')
        .height(1)
        .color($r('sys.color.ohos_id_color_list_separator'))
      
      // 按钮容器
      Row() {
        // 取消按钮
        Button('取消')
          .fontSize(16)
          .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
          .backgroundColor($r('app.color.BG_COLOR'))
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
          .color($r('sys.color.ohos_id_color_list_separator'))
        
        // 确认按钮
        Button('保存')
          .fontSize(16)
          .fontColor($r('app.color.WARNING_COLOR'))  // 使用橙色作为强调色
          .backgroundColor($r('app.color.BG_COLOR'))
          .width('50%')
          .height(48)
          .onClick(() => {
            if (this.onConfirm) {
              this.onConfirm();
            }
          })
      }
      .width('100%')
      .height(48)
    }
    .width('85%')
    .backgroundColor($r('app.color.BG_COLOR'))
    .borderRadius(12)
    .padding({ top: 8, bottom: 0 })
  }
}
