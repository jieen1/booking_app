/**
 * 交易确认对话框组件
 */
import { InvestmentBookModel } from '../../model/InvestmentBookModel';
import { InvestmentAssetModel } from '../../model/InvestmentAssetModel';

// 组件参数接口
interface TransactionConfirmDialogParams {
  book: InvestmentBookModel | null;
  asset: InvestmentAssetModel | null;
  transactionType: string;
  price: number;
  quantity: number;
  fee: number;
  tax: number;
  onConfirm?: () => void;
}

@CustomDialog
export struct TransactionConfirmDialog {
  controller: CustomDialogController;
  book: InvestmentBookModel | null = null;
  asset: InvestmentAssetModel | null = null;
  transactionType: string = '';
  price: number = 0;
  quantity: number = 0;
  fee: number = 0;
  tax: number = 0;
  onConfirm?: () => void;
  
  // 计算交易金额
  private calculateAmount(): number {
    return this.price * this.quantity;
  }
  
  // 计算总金额
  private calculateTotal(): number {
    const amount = this.calculateAmount();
    if (this.transactionType === 'buy') {
      return amount + this.fee + this.tax;
    } else {
      return amount - this.fee - this.tax;
    }
  }
  
  build() {
    Column() {
      // 对话框标题
      Row() {
        Text(this.transactionType === 'buy' ? '确认买入' : '确认卖出')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        
        Blank()
        
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_close'))
            .width(18)
            .height(18)
        }
        .width(32)
        .height(32)
        .backgroundColor('#f5f5f5')
        .onClick(() => {
          this.controller.close();
        })
      }
      .width('100%')
      .padding({ top: 16, bottom: 16, left: 24, right: 24 })
      
      // 交易信息
      if (this.asset) {
        Row() {
          Column() {
            Text(this.asset.name)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            
            Text(this.asset.code)
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          
          Column() {
            Text(`¥${this.asset.currentPrice.toFixed(2)}`)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
        .padding({ left: 24, right: 24, bottom: 16 })
      }
      
      // 账户信息
      if (this.book) {
        Row() {
          Text(`账户: ${this.book.name}`)
            .fontSize(14)
            .fontColor('#666666')
          
          Blank()
          
          Text(`可${this.transactionType === 'buy' ? '用' : '入'}: ¥${this.book.balance.toFixed(2)}`)
            .fontSize(14)
            .fontColor('#666666')
        }
        .width('100%')
        .padding({ left: 24, right: 24, bottom: 16 })
      }
      
      Divider()
        .width('100%')
        .color('#eeeeee')
      
      // 交易详情
      Column() {
        this.buildInfoRow('价格', `¥${this.price.toFixed(2)}`);
        this.buildInfoRow('数量', `${this.quantity} 股`);
        this.buildInfoRow('金额', `¥${this.calculateAmount().toFixed(2)}`);
        this.buildInfoRow('手续费', `¥${this.fee.toFixed(2)}`);
        this.buildInfoRow('税费', `¥${this.tax.toFixed(2)}`);
      }
      .width('100%')
      .padding({ top: 16, bottom: 16, left: 24, right: 24 })
      
      Divider()
        .width('100%')
        .color('#eeeeee')
      
      // 总金额
      Row() {
        Text(this.transactionType === 'buy' ? '支付总金额' : '收到总金额')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        
        Blank()
        
        Text(`¥${this.calculateTotal().toFixed(2)}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ff5722')
      }
      .width('100%')
      .padding({ top: 16, bottom: 24, left: 24, right: 24 })
      
      // 操作按钮
      Row() {
        Button('取消')
          .width('48%')
          .height(44)
          .borderRadius(22)
          .backgroundColor('#f5f5f5')
          .fontColor('#666666')
          .onClick(() => {
            this.controller.close();
          })
        
        Button(this.transactionType === 'buy' ? '确认买入' : '确认卖出')
          .width('48%')
          .height(44)
          .borderRadius(22)
          .backgroundColor(this.transactionType === 'buy' ? '#ff9800' : '#4caf50')
          .fontColor(Color.White)
          .onClick(() => {
            if (this.onConfirm) {
              this.onConfirm();
            }
            this.controller.close();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 24, right: 24, bottom: 24 })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
  
  @Builder
  buildInfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#666666')
      
      Blank()
      
      Text(value)
        .fontSize(14)
        .fontColor('#333333')
    }
    .width('100%')
    .margin({ top: 8, bottom: 8 })
  }
}
