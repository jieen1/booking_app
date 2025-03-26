/**
 * 添加投资资产页面
 * 用于添加新的投资标的
 */
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { InvestmentAssetDBHelper } from '../../database/InvestmentAssetDBHelper';
import { InvestmentAssetModel } from '../../model/InvestmentAssetModel';
import { InvestmentType } from '../../model/InvestmentBookModel';
import { DBConnectionHolder } from '../../database/DBConnectionHolder';
import { SelectionDialog, SelectOption } from '../../components/SelectionDialog';

// 路由参数接口
interface RouteParams {
  bookId?: number;
  onUpdate?: () => void;
}

@Entry
@Component
struct AddAssetPage {
  @State assetName: string = ''; // 资产名称
  @State assetCode: string = ''; // 资产代码
  @State assetType: string = '1'; // 资产类型，默认为股票
  @State isSubmitting: boolean = false; // 是否正在提交
  @State bookId: number = -1; // 账本ID
  onUpdate?: () => void;

  // 资产类型选项
  private assetTypeOptions: SelectOption[] = [
    { value: '1', text: '股票' },
    { value: '2', text: '基金' },
    { value: '3', text: '债券' },
    { value: '4', text: '其他' }
  ];
  
  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as RouteParams;
    if (params && params.bookId) {
      this.bookId = params.bookId;
    }
    if (params && params.onUpdate) {
      this.onUpdate = params.onUpdate;
    }
  }

  // 显示资产类型选择弹窗
  showAssetTypeSelection(): void {
    const dialogController = new CustomDialogController({
      builder: SelectionDialog({
        title: '选择资产类型',
        options: this.assetTypeOptions,
        onSelect: (value) => {
          this.assetType = value;
        }
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });
    dialogController.open();
  }
  
  /**
   * 添加资产
   */
  async addAsset() {
    // 表单验证
    if (!this.assetName.trim()) {
      promptAction.showToast({
        message: '请输入资产名称',
        duration: 2000
      });
      return;
    }
    
    if (!this.assetCode.trim()) {
      promptAction.showToast({
        message: '请输入资产代码',
        duration: 2000
      });
      return;
    }
    
    if (this.bookId <= 0) {
      promptAction.showToast({
        message: '无效的账本ID',
        duration: 2000
      });
      return;
    }
    
    try {
      this.isSubmitting = true;
      
      // 创建资产对象 - 使用默认值初始化价格和数量
      const asset = new InvestmentAssetModel(
        this.bookId,
        this.assetCode,
        this.assetName,
        parseInt(this.assetType) as InvestmentType,
        0, // 初始购入价格为0
        0, // 初始当前价格为0
        0  // 初始数量为0
      );
      
      // 保存到数据库
      const assetDBHelper = new InvestmentAssetDBHelper();
      // 初始化数据库连接
      const dbHolder = DBConnectionHolder.getInstance();
      await dbHolder.initDB();
      
      // 添加资产
      const assetId = await assetDBHelper.addInvestmentAsset(asset);
      
      if (assetId > 0) {
        // 添加成功
        promptAction.showToast({
          message: '添加资产成功',
          duration: 2000
        });
        
        // 返回上一页
        setTimeout(() => {
          router.back();
        }, 1000);
      } else {
        // 添加失败
        promptAction.showToast({
          message: '添加资产失败',
          duration: 2000
        });
      }
    } catch (error) {
      console.error('添加资产失败', error);
      promptAction.showToast({
        message: `添加资产失败: ${error.message || '未知错误'}`,
        duration: 2000
      });
    } finally {
      this.isSubmitting = false;
      if (this.onUpdate) {
        this.onUpdate();
      }
    }
  }
  
  build() {
    Column() {
      Row()
        .height(20)

      // 顶部导航栏
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .margin({ left: 16 })
          .onClick(() => {
            router.back();
          })
        
        Text('添加资产')
          .fontSize(18)
          .fontWeight(500)
          .margin({ left: 16 })
        
        Blank()
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      
      // 表单内容
      Column() {
        // 资产名称
        Row() {
          Text('资产名称:')
            .fontSize(16)
            .fontColor('#666666')
            .width('30%')
          
          TextInput({ placeholder: '请输入资产名称' })
            .width('70%')
            .height(40)
            .backgroundColor('#F5F5F5')
            .borderRadius(4)
            .padding({ left: 10, right: 10 })
            .onChange((value: string) => {
              this.assetName = value;
            })
        }
        .width('100%')
        .margin({ top: 16 })
        
        // 资产代码
        Row() {
          Text('资产代码:')
            .fontSize(16)
            .fontColor('#666666')
            .width('30%')
          
          TextInput({ placeholder: '请输入资产代码' })
            .width('70%')
            .height(40)
            .backgroundColor('#F5F5F5')
            .borderRadius(4)
            .padding({ left: 10, right: 10 })
            .onChange((value: string) => {
              this.assetCode = value;
            })
        }
        .width('100%')
        .margin({ top: 16 })
        
        // 资产类型
        Row() {
          Text('资产类型:')
            .fontSize(16)
            .fontColor('#666666')
            .width('30%')
          
          Column() {
            Text(this.assetTypeOptions.find(item => item.value === this.assetType)?.text || '股票')
              .fontSize(16)
              .fontColor('#333333')
              .width('100%')
              .height(40)
              .backgroundColor('#F5F5F5')
              .borderRadius(4)
              .textAlign(TextAlign.Start)
              .padding({ left: 10, right: 10 })
              .onClick(() => {
                this.showAssetTypeSelection()
              })
          }
          .width('70%')
        }
        .width('100%')
        .margin({ top: 16 })
        
        // 提交按钮
        Button({
          type: ButtonType.Capsule
        }) {
          Row() {
            if (this.isSubmitting) {
              LoadingProgress()
                .width(24)
                .height(24)
                .color(Color.White)
                .margin({ right: 10 })
            }
            
            Text('添加资产')
              .fontSize(16)
              .fontColor(Color.White)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .height(44)
        .backgroundColor('#4fc08d')
        .margin({ top: 32 })
        .enabled(!this.isSubmitting)
        .onClick(() => {
          this.addAsset();
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
