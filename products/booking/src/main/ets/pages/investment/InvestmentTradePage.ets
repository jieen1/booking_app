/**
 * 投资交易页面 - 统一处理买入和卖出操作
 */
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { InvestmentAssetDBHelper } from '../../database/InvestmentAssetDBHelper';
import { InvestmentTransactionDBHelper } from '../../database/InvestmentTransactionDBHelper';
import { InvestmentTransactionModel, TransactionType } from '../../model/InvestmentTransactionModel';
import { SelectionDialog, SelectOption } from '../../components/SelectionDialog';

// 路由参数接口
interface RouteParams {
  bookId?: number;
  bookName?: string;
  tradeType: string;
}

@Entry
@Component
export struct InvestmentTradePage {
  @State bookId: number = -1;
  @State bookName: string = '';
  @State tradeType: string = 'buy'; // 默认为买入模式
  @State assetName: string = '';
  @State assetType: number = 1; // 默认为股票类型
  @State amount: number = 0;
  @State price: number = 0;
  @State fee: number = 0;
  @State date: string = this.formatDate(new Date());
  @State remark: string = '';
  @State isSubmitting: boolean = false;
  @State assetCode: string = ''; // 证券代码
  @State showAssetTypeDialog: boolean = false; // 是否显示资产类型弹窗
  
  // 资产类型选项
  private assetTypeOptions: SelectOption[] = [
    { value: '1', text: '股票' },
    { value: '2', text: '基金' },
    { value: '3', text: '债券' },
    { value: '4', text: '期货' },
    { value: '5', text: '其他' }
  ];
  
  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as RouteParams;
    if (params.bookId) {
      this.bookId = params.bookId;
    }

    if (params.bookName) {
      this.bookName = params.bookName;
    }
    
    if (params.tradeType) {
      this.tradeType = params.tradeType;
    }
    
    // 自动填充日期为今天
    this.date = this.formatDate(new Date());
  }
  
  // 格式化日期为YYYY-MM-DD
  private formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
  }
  
  // 计算交易总额
  getTotal(): number {
    return this.price * this.amount + this.fee;
  }
  
  // 保存交易记录
  async saveTransaction() {
    if (this.isSubmitting) {
      return;
    }
    
    // 表单验证
    if (!this.assetName) {
      promptAction.showToast({ message: '请输入资产名称', duration: 2000 });
      return;
    }
    
    if (this.amount <= 0) {
      promptAction.showToast({ message: '请输入有效的数量', duration: 2000 });
      return;
    }
    
    if (this.price <= 0) {
      promptAction.showToast({ message: '请输入有效的价格', duration: 2000 });
      return;
    }
    
    try {
      this.isSubmitting = true;
      
      // 获取资产ID或创建新资产
      const assetHelper = InvestmentAssetDBHelper.getInstance();
      const asset = await assetHelper.getOrCreateAsset(
        this.bookId,        // 账本ID
        this.assetCode,     // 证券代码
        this.assetName,     // 证券名称
        this.assetType,     // 资产类型
        this.price,         // 购入价格
        this.price,         // 当前价格（交易时与购入价格相同）
        this.amount  // 数量（金额除以价格）
      );
      
      // 创建交易记录
      const transactionHelper = InvestmentTransactionDBHelper.getInstance();
      const transactionType = this.tradeType === 'buy' ? TransactionType.BUY : TransactionType.SELL; // 使用枚举
      
      // 使用ITransactionParam接口创建参数对象
      const transactionParam: InvestmentTransactionModel = new InvestmentTransactionModel(this.bookId, asset.id || 0, transactionType, this.price, this.amount / this.price, this.amount, this.fee, 0, this.remark, new Date(this.date).getTime());

      const result = await transactionHelper.createTransaction(transactionParam);
      
      if (result) {
        promptAction.showToast({
          message: this.tradeType === 'buy' ? '买入成功' : '卖出成功',
          duration: 2000
        });
        // 返回到上一页
        setTimeout(() => {
          router.back();
        }, 1500);
      } else {
        promptAction.showToast({
          message: '保存失败，请重试',
          duration: 2000
        });
        this.isSubmitting = false;
      }
    } catch (error) {
      console.error('保存交易记录失败', error);
      promptAction.showToast({
        message: '操作失败，请重试',
        duration: 2000
      });
      this.isSubmitting = false;
    }
  }
  
  // 显示资产类型选择弹窗
  showAssetTypeSelection(): void {
    const controller = SelectionDialog.create({
      title: '选择资产类型',
      options: this.assetTypeOptions,
      onSelect: (value) => {
        this.assetType = parseInt(value);
        this.showAssetTypeDialog = false;
      },
      onCancel: () => {
        this.showAssetTypeDialog = false;
      }
    });
    controller.open();
  }
  
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        // 顶部导航栏
        Row() {
          Image($r('app.media.ic_back'))
            .width(24)
            .height(24)
            .margin({ right: 16 })
            .onClick(() => {
              router.back();
            })
          Text(this.tradeType === 'buy' ? '买入资产' : '卖出资产')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#FFFFFF')
        
        // 交易类型切换
        Row() {
          Button({ type: ButtonType.Capsule, stateEffect: true }) {
            Text('买入')
              .fontColor(this.tradeType === 'buy' ? '#FFFFFF' : '#333333')
              .fontSize(16)
          }
          .backgroundColor(this.tradeType === 'buy' ? '#4CAF50' : '#F5F5F5')
          .width('48%')
          .height(40)
          .onClick(() => {
            this.tradeType = 'buy';
          })
          
          Button({ type: ButtonType.Capsule, stateEffect: true }) {
            Text('卖出')
              .fontColor(this.tradeType === 'sell' ? '#FFFFFF' : '#333333')
              .fontSize(16)
          }
          .backgroundColor(this.tradeType === 'sell' ? '#FF9800' : '#F5F5F5')
          .width('48%')
          .height(40)
          .onClick(() => {
            this.tradeType = 'sell';
          })
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ top: 16, bottom: 16 })
        
        // 表单内容
        Scroll() {
          Column() {
            // 账本信息
            Row() {
              Text('交易账本:')
                .fontSize(16)
                .fontColor('#666666')
                .width('30%')
              Text(this.bookName)
                .fontSize(16)
                .fontColor('#333333')
                .width('70%')
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .margin({ bottom: 12 })
            
            // 资产名称
            Row() {
              Text('资产名称:')
                .fontSize(16)
                .fontColor('#666666')
                .width('30%')
              TextInput({ placeholder: '请输入资产名称' })
                .fontSize(16)
                .width('70%')
                .backgroundColor('#00000000')
                .onChange((value: string) => {
                  this.assetName = value;
                })
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .margin({ bottom: 12 })
            
            // 资产代码
            Row() {
              Text('资产代码:')
                .fontSize(16)
                .fontColor('#666666')
                .width('30%')
              TextInput({ placeholder: '请输入资产代码' })
                .fontSize(16)
                .width('70%')
                .backgroundColor('#00000000')
                .onChange((value: string) => {
                  this.assetCode = value;
                })
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .margin({ bottom: 12 })
            
            // 资产类型
            Row() {
              Text('资产类型:')
                .fontSize(16)
                .fontColor('#666666')
                .width('30%')
              
              // 使用SelectionDialog显示资产类型弹窗
              Column() {
                Row() {
                  Text(this.assetTypeOptions[parseInt(this.assetType.toString()) - 1].text)
                    .fontSize(16)
                    .width('90%')
                  
                  Image($r('app.media.ic_down_cartoon_new'))
                    .width(20)
                    .height(20)
                    .margin({ left: 5 })
                }
                .width('100%')
                .height(40)
                .justifyContent(FlexAlign.SpaceBetween)
                .alignItems(VerticalAlign.Center)
                .borderRadius(4)
                .backgroundColor('#F5F5F5')
                .padding({ left: 10, right: 10 })
                .onClick(() => {
                  this.showAssetTypeSelection();
                })
              }
              .width('70%')
            }
            .width('100%')
            .margin({ top: 10, bottom: 10 })
            
            // 交易数量
            Row() {
              Text('交易数量:')
                .fontSize(16)
                .fontColor('#666666')
                .width('30%')
              TextInput({ placeholder: '请输入数量' })
                .fontSize(16)
                .width('70%')
                .backgroundColor('#00000000')
                .type(InputType.Number)
                .onChange((value: string) => {
                  this.amount = parseFloat(value) || 0;
                })
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .margin({ bottom: 12 })
            
            // 交易价格
            Row() {
              Text('单价:')
                .fontSize(16)
                .fontColor('#666666')
                .width('30%')
              TextInput({ placeholder: '请输入单价' })
                .fontSize(16)
                .width('70%')
                .backgroundColor('#00000000')
                .type(InputType.NUMBER_DECIMAL)
                .onChange((value: string) => {
                  this.price = parseFloat(value) || 0;
                })
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .margin({ bottom: 12 })
            
            // 手续费
            Row() {
              Text('手续费:')
                .fontSize(16)
                .fontColor('#666666')
                .width('30%')
              TextInput({ placeholder: '请输入手续费' })
                .fontSize(16)
                .width('70%')
                .backgroundColor('#00000000')
                .type(InputType.NUMBER_DECIMAL)
                .onChange((value: string) => {
                  this.fee = parseFloat(value) || 0;
                })
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .margin({ bottom: 12 })
            
            // 交易日期
            Row() {
              Text('交易日期:')
                .fontSize(16)
                .fontColor('#666666')
                .width('30%')
              TextInput({ placeholder: '请输入日期', text: this.date })
                .fontSize(16)
                .width('70%')
                .backgroundColor('#00000000')
                .onChange((value: string) => {
                  this.date = value;
                })
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .margin({ bottom: 12 })
            
            // 备注
            Row() {
              Text('备注:')
                .fontSize(16)
                .fontColor('#666666')
                .width('30%')
              TextInput({ placeholder: '请输入备注(选填)' })
                .fontSize(16)
                .width('70%')
                .backgroundColor('#00000000')
                .onChange((value: string) => {
                  this.remark = value;
                })
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .margin({ bottom: 12 })
            
            // 交易总额
            Row() {
              Text('交易总额:')
                .fontSize(16)
                .fontColor('#666666')
                .width('30%')
              Text(`¥ ${this.getTotal().toFixed(2)}`)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.tradeType === 'buy' ? '#4CAF50' : '#FF9800')
                .width('70%')
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .margin({ bottom: 24 })
          }
          .width('90%')
          .padding({ bottom: 80 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        
        // 底部按钮
        Row() {
          Button() {
            if (this.isSubmitting) {
              LoadingProgress()
                .width(24)
                .height(24)
                .color(Color.White)
            } else {
              Text(this.tradeType === 'buy' ? '确认买入' : '确认卖出')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
            }
          }
          .width('90%')
          .height(50)
          .backgroundColor('#FF7500')
          .borderRadius(25)
          .enabled(!this.isSubmitting)
          .onClick(() => this.saveTransaction())
        }
        .width('100%')
        .height(80)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
