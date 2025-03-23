/**
 * 投资账本卡片组件
 * 显示投资账本的基本信息、余额和收益率
 */
import prompt from '@ohos.prompt';
import router from '@ohos.router';
import { InvestmentBookModel } from '../../model/InvestmentBookModel';
import { InvestmentBookDBHelper } from '../../database/InvestmentBookDBHelper';

@Component
export struct InvestmentBookCard {
  @ObjectLink book: InvestmentBookModel;
  @State profit: number = 0;
  @State profitRate: number = 0;
  @State isDeleting: boolean = false;
  
  aboutToAppear(): void {
    this.calculateProfit();
  }
  
  calculateProfit(): void {
    // 计算收益和收益率
    const initialInvestment: number = this.book.initialInvestment || 0;
    const currentAmount: number = this.book.balance || 0;
    this.profit = currentAmount - initialInvestment;
    this.profitRate = initialInvestment > 0 ? (this.profit / initialInvestment) * 100 : 0;
  }
  
  async deleteBook(): Promise<void> {
    try {
      this.isDeleting = true;
      const bookHelper: InvestmentBookDBHelper = InvestmentBookDBHelper.getInstance();
      
      if (this.book.id === undefined) {
        throw new Error('账本ID不存在');
      }
      
      await bookHelper.deleteInvestmentBook(this.book.id);
      
      prompt.showToast({
        message: '删除成功',
        duration: 2000
      });
      
      // 刷新页面
      router.back();
      setTimeout(() => {
        router.pushUrl({ url: 'pages/InvestmentOverviewPage' });
      }, 100);
    } catch (error) {
      console.error('删除投资账本失败', error);
      prompt.showToast({
        message: '删除失败',
        duration: 2000
      });
    } finally {
      this.isDeleting = false;
    }
  }
  
  build() {
    Stack() {
      Column() {
        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          Column() {
            Text(this.book.name)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 8 });
            
            Text(`¥${this.book.balance.toFixed(2)}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 8 });
            
            Row() {
              if (this.profit >= 0) {
                Text(`+¥${this.profit.toFixed(2)}`)
                  .fontSize(14)
                  .fontColor('#4CAF50');
              } else {
                Text(`-¥${Math.abs(this.profit).toFixed(2)}`)
                  .fontSize(14)
                  .fontColor('#F44336');
              }
              
              Text(` (${this.profitRate >= 0 ? '+' : ''}${this.profitRate.toFixed(2)}%)`)
                .fontSize(14)
                .fontColor(this.profitRate >= 0 ? '#4CAF50' : '#F44336');
            }
          }
          .alignItems(HorizontalAlign.Start);
          
          Column() {
            Button({ type: ButtonType.Circle, stateEffect: true }) {
              Image($r('app.media.ic_other'))
                .width(24)
                .height(24)
                .fillColor('#666666');
            }
            .width(32)
            .height(32)
            .backgroundColor('rgba(0,0,0,0.05)')
            .bindMenu(this.getBindMenu());
          }
          .width(32);
        }
        .width('100%')
        .padding({ top: 16, bottom: 16, left: 20, right: 20 });
      }
      .width('100%')
      .borderRadius(12)
      .backgroundColor(Color.White)
      // 添加毛玻璃效果
      .backgroundBlurStyle(BlurStyle.Thin)
      .borderWidth(1)
      .borderColor('#eeeeee');
      
      if (this.isDeleting) {
        // 显示加载中
        LoadingProgress()
          .color('#FF9800')
          .width(30)
          .height(30)
          .position({ x: '50%', y: '50%' });
      }
    }
    .width('100%')
    .height(140)
    .margin({ bottom: 12 })
    .onClick(() => {
      if (!this.isDeleting && this.book.id) {
        router.pushUrl({
          url: 'pages/InvestmentDetailPage',
          params: {
            bookId: this.book.id
          }
        });
      }
    });
  }
  
  @Builder
  getBindMenu() {
    Menu() {
      MenuItem({ content: '编辑账本' })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/investment/EditInvestmentBookPage',
            params: {
              book: this.book
            }
          });
        });
      
      MenuItem({ content: '删除账本' })
        .onClick(() => {
          AlertDialog.show({
            title: '确认删除',
            message: '确定要删除该投资账本吗？删除后无法恢复。',
            autoCancel: true,
            alignment: DialogAlignment.Center,
            offset: { dx: 0, dy: -20 },
            primaryButton: {
              value: '取消',
              action: () => {
                console.info('取消删除');
              }
            },
            secondaryButton: {
              value: '删除',
              fontColor: '#FF3D71',
              action: () => {
                this.deleteBook();
              }
            }
          });
        });
    }
  }
}
