/**
 * 首页投资摘要卡片组件
 * 显示投资总览和快速入口
 */
import router from '@ohos.router';
import { InvestmentBookDBHelper } from '../../database/InvestmentBookDBHelper';
import { InvestmentAssetDBHelper } from '../../database/InvestmentAssetDBHelper';

interface ISummaryData {
  totalAssets: number;
  totalProfit: number;
  totalProfitRate: number;
}

@Component
export struct HomeInvestmentSummaryCard {
  @State summaryData: ISummaryData = {
    totalAssets: 0,
    totalProfit: 0,
    totalProfitRate: 0
  };
  @State isLoading: boolean = true;

  aboutToAppear() {
    this.loadInvestmentSummary();
  }

  async loadInvestmentSummary() {
    try {
      this.isLoading = true;
      // 从数据库获取投资数据
      const bookHelper = InvestmentBookDBHelper.getInstance();
      const books = await bookHelper.getAllInvestmentBooks();
      
      if (books && books.length > 0) {
        let totalAssets = 0;
        let totalCost = 0;
        
        for (const book of books) {
          totalAssets += book.balance || 0;
          totalCost += book.initialInvestment || 0;
        }
        
        const totalProfit = totalAssets - totalCost;
        const totalProfitRate = totalCost > 0 ? (totalProfit / totalCost) * 100 : 0;
        
        this.summaryData = {
          totalAssets: totalAssets,
          totalProfit: totalProfit,
          totalProfitRate: totalProfitRate
        };
      }
    } catch (error) {
      console.error('加载投资摘要数据失败', error);
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 标题
      Row() {
        Text('投资总览')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Blank()

        Text('查看更多 >')
          .fontSize(14)
          .fontColor('#666666')
          .onClick(() => {
            router.pushUrl({ url: 'pages/InvestmentOverviewPage' });
          })
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })

      if (this.isLoading) {
        // 加载状态
        Row() {
          LoadingProgress()
            .width(24)
            .height(24)
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ left: 8 })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .height(100)
      } else {
        // 投资数据
        Row() {
          // 总资产
          Column() {
            Text('总资产')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 4 })
            
            Text(`¥${this.summaryData.totalAssets.toFixed(2)}`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          
          // 分隔线
          Divider()
            .vertical(true)
            .height(40)
            .color('#eeeeee')
          
          // 总收益
          Column() {
            Text('总收益')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 4 })
            
            Text(`${this.summaryData.totalProfit >= 0 ? '+' : ''}¥${this.summaryData.totalProfit.toFixed(2)}`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.summaryData.totalProfit >= 0 ? '#ff5722' : '#4caf50')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          
          // 分隔线
          Divider()
            .vertical(true)
            .height(40)
            .color('#eeeeee')
          
          // 收益率
          Column() {
            Text('收益率')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 4 })
            
            Text(`${this.summaryData.totalProfitRate >= 0 ? '+' : ''}${this.summaryData.totalProfitRate.toFixed(2)}%`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.summaryData.totalProfitRate >= 0 ? '#ff5722' : '#4caf50')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding({ top: 8, bottom: 16 })
      }
      
      // 快捷操作按钮
      Row() {
        Button() {
          Row() {
            Image($r('app.media.ic_investment'))
              .width(20)
              .height(20)
              .margin({ right: 8 })
            
            Text('投资管理')
              .fontSize(14)
              .fontColor('#ffffff')
          }
        }
        .backgroundColor('#4fc08d')
        .borderRadius(24)
        .height(36)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/InvestmentOverviewPage' });
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 8, bottom: 12 })
    }
    .width('95%')
    .padding({ left: 16, right: 16 })
    .borderRadius(16)
    .backgroundColor($r('app.color.BG_COLOR_SECONDARY'))
    .margin({ bottom: 16 })
    // 添加毛玻璃效果
    .backdropBlur(8)
    .shadow(ShadowStyle.OUTER_DEFAULT_SM)
  }
}
