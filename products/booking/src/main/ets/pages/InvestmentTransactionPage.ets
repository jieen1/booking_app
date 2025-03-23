/**
 * 投资交易页面
 * 实现买入和卖出投资品种的操作
 */
import router from '@ohos.router';
import prompt from '@ohos.prompt';
import { InvestmentBookModel } from '../model/InvestmentBookModel';
import { InvestmentAssetModel } from '../model/InvestmentAssetModel';
import { InvestmentTransactionModel, TransactionType } from '../model/InvestmentTransactionModel';
import { InvestmentBookDBHelper } from '../database/InvestmentBookDBHelper';
import { InvestmentTransactionDBHelper } from '../database/InvestmentTransactionDBHelper';
import { InvestmentAssetDBHelper } from '../database/InvestmentAssetDBHelper';
import { AssetSelector } from '../components/investment/AssetSelector';
import { TransactionConfirmDialog } from '../components/investment/TransactionConfirmDialog';

/**
 * 路由参数接口
 */
interface RouteParams {
  bookId: number;
  type: string;
  assetId?: number;
}

@Entry
@Component
export struct InvestmentTransactionPage {
  @State bookId: number = 0;
  @State book: InvestmentBookModel | null = null;
  @State transactionType: string = 'buy'; // buy 或 sell
  @State selectedAsset: InvestmentAssetModel | null = null;
  @State price: number = 0;
  @State quantity: number = 0;
  @State fee: number = 0;
  @State tax: number = 0;
  @State relatedAccountId: number = 0;
  @State remarks: string = '';
  @State assets: InvestmentAssetModel[] = [];
  @State isLoading: boolean = true;
  
  dialogController: CustomDialogController = new CustomDialogController({
    builder: TransactionConfirmDialog({
      book: this.book,
      asset: this.selectedAsset,
      transactionType: this.transactionType,
      price: this.price,
      quantity: this.quantity,
      fee: this.fee,
      tax: this.tax,
      onConfirm: () => this.saveTransaction()
    }),
    autoCancel: true,
    alignment: DialogAlignment.Bottom,
    customStyle: true
  });
  
  aboutToAppear(): void {
    // 获取路由参数
    const params = router.getParams() as RouteParams;
    if (params) {
      this.bookId = params.bookId || 0;
      if (params.type) {
        this.transactionType = params.type;
      }
      
      // 如果指定了资产ID，则直接加载该资产
      if (params.assetId !== undefined) {
        this.loadAssetById(params.assetId);
      }
    }
    
    this.loadBookData();
    this.loadAssets();
  }
  
  async loadBookData() {
    try {
      this.isLoading = true;
      const bookHelper = InvestmentBookDBHelper.getInstance();
      const book = await bookHelper.getInvestmentBookById(this.bookId);
      if (book) {
        this.book = book;
        await this.loadAssets();
      } else {
        prompt.showToast({
          message: '账本不存在',
          duration: 2000
        });
        router.back();
      }
    } catch (error) {
      console.error('加载账本数据错误', error);
    } finally {
      this.isLoading = false;
    }
  }
  
  async loadAssets() {
    try {
      const assetHelper = InvestmentAssetDBHelper.getInstance();
      const assets = await assetHelper.getAssetsByBookId(this.bookId);
      this.assets = assets;
    } catch (error) {
      console.error('加载资产数据错误', error);
    }
  }
  
  async loadAssetById(assetId: number) {
    try {
      const assetHelper = InvestmentAssetDBHelper.getInstance();
      const asset = await assetHelper.getInvestmentAssetById(assetId);
      if (asset) {
        this.selectedAsset = asset;
        this.price = asset.currentPrice;
      }
    } catch (error) {
      console.error('加载资产数据错误', error);
    }
  }
  
  /**
   * 选择投资品种
   * @param asset 选择的投资品种
   */
  selectAsset(asset: InvestmentAssetModel): void {
    this.selectedAsset = asset;
  }
  
  /**
   * 计算交易金额
   * @returns 交易金额
   */
  calculateAmount(): number {
    return this.price * this.quantity;
  }
  
  /**
   * 计算手续费
   * @returns 手续费
   */
  calculateFee(): number {
    return this.fee;
  }
  
  /**
   * 计算税费
   * @returns 税费
   */
  calculateTax(): number {
    return this.tax;
  }
  
  /**
   * 计算总金额
   * @returns 总金额
   */
  calculateTotal(): number {
    // 买入时，总金额 = 交易金额 + 手续费 + 税费
    // 卖出时，总金额 = 交易金额 - 手续费 - 税费
    const amount = this.calculateAmount();
    const fee = this.calculateFee();
    const tax = this.calculateTax();
    
    if (this.transactionType === 'buy') {
      return amount + fee + tax;
    } else {
      return amount - fee - tax;
    }
  }
  
  /**
   * 验证交易信息是否有效
   * @returns 验证结果
   */
  validateTransaction(): boolean {
    // 检查必填信息
    if (!this.selectedAsset) {
      prompt.showToast({
        message: '请选择投资品种',
        duration: 2000
      });
      return false;
    }
    
    if (this.price <= 0) {
      prompt.showToast({
        message: '请输入有效的价格',
        duration: 2000
      });
      return false;
    }
    
    if (this.quantity <= 0) {
      prompt.showToast({
        message: '请输入有效的数量',
        duration: 2000
      });
      return false;
    }
    
    // 如果是卖出操作，检查持仓数量
    if (this.transactionType === 'sell' && this.selectedAsset && this.quantity > this.selectedAsset.quantity) {
      prompt.showToast({
        message: '卖出数量不能超过持仓数量',
        duration: 2000
      });
      return false;
    }
    
    return true;
  }
  
  showConfirmDialog() {
    if (!this.validateTransaction()) {
      return;
    }
    
    // 更新确认对话框的数据
    this.dialogController = new CustomDialogController({
      builder: TransactionConfirmDialog({
        book: this.book,
        asset: this.selectedAsset,
        transactionType: this.transactionType,
        price: this.price,
        quantity: this.quantity,
        fee: this.fee,
        tax: this.tax,
        onConfirm: () => this.saveTransaction()
      }),
      autoCancel: true,
      alignment: DialogAlignment.Bottom,
      customStyle: true
    });
    
    this.dialogController.open();
  }
  
  /**
   * 保存交易记录
   */
  async saveTransaction(): Promise<void> {
    if (!this.validateTransaction() || !this.selectedAsset || !this.book) {
      return;
    }
    
    try {
      // 创建交易记录
      const transaction = new InvestmentTransactionModel(
        this.bookId,
        this.selectedAsset?.id,
        this.transactionType === 'buy' ? TransactionType.BUY : TransactionType.SELL,
        this.price,
        this.quantity,
        this.price * this.quantity, // 计算交易金额
        this.fee,
        this.relatedAccountId,
        this.remarks,
        Date.now()
      );
      
      // 保存交易记录
      const transactionHelper = InvestmentTransactionDBHelper.getInstance();
      const transactionId = await transactionHelper.createTransaction(transaction);
      
      if (transactionId <= 0) {
        prompt.showToast({
          message: '保存交易记录失败',
          duration: 2000
        });
        return;
      }
      
      // 更新资产持仓数量
      const assetHelper = InvestmentAssetDBHelper.getInstance();
      if (this.selectedAsset) {
        const asset = this.selectedAsset;
        if (this.transactionType === 'buy') {
          // 买入操作，增加持仓数量
          asset.quantity += this.quantity;
        } else {
          // 卖出操作，减少持仓数量
          asset.quantity -= this.quantity;
        }

        await assetHelper.updateInvestmentAsset(asset);
      }
      
      // 显示交易成功提示
      prompt.showToast({
        message: '交易已完成',
        duration: 2000
      });
      
      // 返回上一页
      router.back();
    } catch (error) {
      console.error('保存交易记录失败', error);
      prompt.showToast({
        message: `保存失败: ${error.message}`,
        duration: 3000
      });
    }
  }
  
  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_back'))
            .width(24)
            .height(24)
        }
        .width(36)
        .height(36)
        .backgroundColor('rgba(255, 255, 255, 0.6)')
        .onClick(() => router.back())
        
        Text(this.transactionType === 'buy' ? '买入' : '卖出')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
        
        Blank()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 8 })
      
      // 交易类型选择
      Row() {
        Button({ type: ButtonType.Capsule }) {
          Text('买入')
            .fontSize(16)
            .fontColor(this.transactionType === 'buy' ? Color.White : '#ff9800')
        }
        .backgroundColor(this.transactionType === 'buy' ? '#ff9800' : 'rgba(255, 152, 0, 0.1)')
        .height(40)
        .width('48%')
        .onClick(() => {
          this.transactionType = 'buy';
        })
        
        Button({ type: ButtonType.Capsule }) {
          Text('卖出')
            .fontSize(16)
            .fontColor(this.transactionType === 'sell' ? Color.White : '#4caf50')
        }
        .backgroundColor(this.transactionType === 'sell' ? '#4caf50' : 'rgba(76, 175, 80, 0.1)')
        .height(40)
        .width('48%')
        .onClick(() => {
          this.transactionType = 'sell';
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      
      Scroll() {
        Column() {
          // 选择投资品种
          Column() {
            Text('选择品种')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .width('100%')
              .margin({ bottom: 12 })
            
            if (this.selectedAsset) {
              // 显示已选择的投资品种
              Row() {
                Column() {
                  Text(this.selectedAsset.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                  
                  Text(this.selectedAsset.code)
                    .fontSize(14)
                    .fontColor('#666666')
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                
                Blank()
                
                Button({ type: ButtonType.Circle }) {
                  Image($r('app.media.ic_edit_cartoon_new'))
                    .width(20)
                    .height(20)
                }
                .width(32)
                .height(32)
                .backgroundColor('#f5f5f5')
                .onClick(() => {
                  // 取消选择投资品种
                  this.selectedAsset = null;
                })
              }
              .width('100%')
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(8)
            } else {
              // 显示投资品种选择器
              AssetSelector({
                assets: this.assets,
                bookId: this.bookId,
                onSelect: (asset) => this.selectAsset(asset)
              })
            }
          }
          .width('100%')
          .padding(16)
          .margin({ bottom: 16 })
          .backgroundColor(Color.White)
          .borderRadius(12)
          
          // 交易信息输入区域
          Column() {
            Text('交易信息')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .width('100%')
              .margin({ bottom: 12 })
            
            // 价格输入
            Row() {
              Text('价格')
                .fontSize(16)
                .width(80)
              
              TextInput({ text: this.price.toString() })
                .type(InputType.Number)
                .layoutWeight(1)
                .height(48)
                .backgroundColor('#f5f5f5')
                .borderRadius(24)
                .padding({ left: 16, right: 16 })
                .onChange((value) => {
                  this.price = parseFloat(value) || 0;
                })
            }
            .width('100%')
            .margin({ bottom: 16 })
            
            // 数量输入
            Row() {
              Text('数量')
                .fontSize(16)
                .width(80)
              
              TextInput({ text: this.quantity > 0 ? this.quantity.toString() : '' })
                .type(InputType.Number)
                .layoutWeight(1)
                .height(48)
                .backgroundColor('#f5f5f5')
                .borderRadius(24)
                .padding({ left: 16, right: 16 })
                .onChange((value) => {
                  this.quantity = parseInt(value) || 0;
                })
            }
            .width('100%')
            .margin({ bottom: 16 })
            
            // 手续费输入
            Row() {
              Text('手续费')
                .fontSize(16)
                .width(80)
              
              TextInput({ text: this.fee > 0 ? this.fee.toString() : '' })
                .type(InputType.Number)
                .layoutWeight(1)
                .height(48)
                .backgroundColor('#f5f5f5')
                .borderRadius(24)
                .padding({ left: 16, right: 16 })
                .onChange((value) => {
                  this.fee = parseFloat(value) || 0;
                })
            }
            .width('100%')
            .margin({ bottom: 16 })
            
            // 税费输入
            Row() {
              Text('税费')
                .fontSize(16)
                .width(80)
              
              TextInput({ text: this.tax > 0 ? this.tax.toString() : '' })
                .type(InputType.Number)
                .layoutWeight(1)
                .height(48)
                .backgroundColor('#f5f5f5')
                .borderRadius(24)
                .padding({ left: 16, right: 16 })
                .onChange((value) => {
                  this.tax = parseFloat(value) || 0;
                })
            }
            .width('100%')
            .margin({ bottom: 16 })
            
            // 备注输入
            Row() {
              Text('备注')
                .fontSize(16)
                .width(80)
              
              TextInput({ text: this.remarks })
                .layoutWeight(1)
                .height(48)
                .backgroundColor('#f5f5f5')
                .borderRadius(24)
                .padding({ left: 16, right: 16 })
                .onChange((value) => {
                  this.remarks = value;
                })
            }
            .width('100%')
            .margin({ bottom: 16 })
          }
          .width('100%')
          .padding(16)
          .margin({ bottom: 16 })
          .backgroundColor(Color.White)
          .borderRadius(12)
          
          // 金额摘要
          Column() {
            Text('金额摘要')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .width('100%')
              .margin({ bottom: 12 })
            
            Row() {
              Text('交易金额')
                .fontSize(16)
                .fontColor('#666666')
              
              Blank()
              
              Text(`¥${this.calculateAmount().toFixed(2)}`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .margin({ bottom: 12 })
            
            Row() {
              Text('手续费')
                .fontSize(16)
                .fontColor('#666666')
              
              Blank()
              
              Text(`¥${this.fee.toFixed(2)}`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .margin({ bottom: 12 })
            
            Row() {
              Text('税费')
                .fontSize(16)
                .fontColor('#666666')
              
              Blank()
              
              Text(`¥${this.tax.toFixed(2)}`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .margin({ bottom: 12 })
            
            Divider()
              .width('100%')
              .color('#eeeeee')
              .margin({ top: 8, bottom: 16 })
            
            Row() {
              Text('总金额')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
              
              Blank()
              
              Text(`¥${this.calculateTotal().toFixed(2)}`)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.transactionType === 'buy' ? '#4fc08d' : '#ff5722')
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      
      // 底部确认按钮
      Button({
        type: ButtonType.Capsule,
        stateEffect: true
      }) {
        Text(this.transactionType === 'buy' ? '确认买入' : '确认卖出')
          .fontSize(18)
          .fontColor(Color.White)
      }
      .width('90%')
      .height(50)
      .backgroundColor(this.transactionType === 'buy' ? '#4fc08d' : '#ff5722')
      .margin({ bottom: 20 })
      .onClick(() => {
        this.showConfirmDialog();
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8f8f8')
  }
}
