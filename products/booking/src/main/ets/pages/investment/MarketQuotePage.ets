/**
 * 市场行情录入页面
 * 用于管理和录入投资品种的市场行情数据
 */
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { MarketQuoteDBHelper } from '../../database/MarketQuoteDBHelper';
import { MarketQuoteModel } from '../../model/MarketQuoteModel';
import { InvestmentAssetDBHelper } from '../../database/InvestmentAssetDBHelper';
import { InvestmentAssetModel } from '../../model/InvestmentAssetModel';
import { DBConnectionHolder } from '../../database/DBConnectionHolder';
import { SelectionDialog, SelectOption } from '../../components/SelectionDialog';

// 选项接口
interface AssetOption {
  value: string;
  text: string;
}

// 错误接口
interface ErrorInfo {
  message: string;
}

// 添加路由参数类型
interface RouterParams {
  bookId: number;
  bookName: string;
  tradeType?: string; // 添加可选的tradeType参数
}

@Entry
@Component
struct MarketQuotePage {
  @State quotes: MarketQuoteModel[] = [];
  @State assets: InvestmentAssetModel[] = [];
  @State isLoading: boolean = false;
  @State selectedAssetIndex: number = -1;
  @State currentPrice: string = '';
  @State assetOptions: AssetOption[] = [];
  @State bookId: number = -1;

  // 数据库帮助类
  private quoteDBHelper: MarketQuoteDBHelper = new MarketQuoteDBHelper();
  private assetDBHelper: InvestmentAssetDBHelper = new InvestmentAssetDBHelper();
  
  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as RouterParams;
    if (params && params.bookId) {
      this.bookId = params.bookId as number;
    }
    
    this.loadData();
  }
  
  /**
   * 加载数据
   */
  async loadData() {
    try {
      this.isLoading = true;
      
      // 初始化数据库连接
      const dbHolder = DBConnectionHolder.getInstance();
      await dbHolder.initDB();
      
      // 加载所有资产
      const assets = await this.assetDBHelper.getAssetsByBookId(this.bookId);
      this.assets = assets;
      
      // 生成选项
      this.assetOptions = assets.map((asset, index) => ({
        value: index.toString(),
        text: `${asset.name}(${asset.code})`
      } as AssetOption));
      
      // 加载所有行情
      const quotes = await this.quoteDBHelper.getAllQuotes();
      this.quotes = quotes;
      
    } catch (error) {
      const err = error as ErrorInfo;
      console.error('加载数据失败', err);
      promptAction.showToast({
        message: `加载数据失败: ${err.message || '未知错误'}`,
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 保存行情
   */
  async saveQuote() {
    // 检验输入
    if (this.selectedAssetIndex < 0) {
      promptAction.showToast({
        message: '请选择资产',
        duration: 2000
      });
      return;
    }
    
    if (!this.currentPrice) {
      promptAction.showToast({
        message: '请输入当前价格',
        duration: 2000
      });
      return;
    }
    
    const price = parseFloat(this.currentPrice);
    if (isNaN(price) || price <= 0) {
      promptAction.showToast({
        message: '请输入有效的价格',
        duration: 2000
      });
      return;
    }
    
    try {
      this.isLoading = true;
      
      // 获取选中的资产
      const asset = this.assets[this.selectedAssetIndex];
      
      // 查找现有行情
      let quote = this.quotes.find(q => q.code === asset.code);
      
      // 如果不存在，创建新的行情对象
      if (!quote) {
        quote = new MarketQuoteModel(
          asset.code,
          asset.name,
          price
        );
      } else {
        // 计算涨跌额和涨跌幅
        const changeAmount = price - quote.closePrice;
        const changePercent = quote.closePrice > 0 ? 
          (changeAmount / quote.closePrice) * 100 : 0;
        
        // 更新行情数据
        quote.currentPrice = price;
        quote.changeAmount = parseFloat(changeAmount.toFixed(2));
        quote.changePercent = parseFloat(changePercent.toFixed(2));
      }
      
      quote.updateTime = new Date().getTime();
      
      // 保存或更新行情
      const success = await this.quoteDBHelper.saveOrUpdateQuote(quote);
      
      if (success) {
        promptAction.showToast({
          message: '行情保存成功',
          duration: 2000
        });
        
        // 更新资产的当前价格
        asset.currentPrice = price;
        
        // 重新计算市值和收益
        asset.marketValue = price * asset.quantity;
        asset.profit = asset.marketValue - asset.cost;
        asset.profitRate = asset.cost > 0 ? 
          (asset.profit / asset.cost) * 100 : 0;
        
        // 更新资产数据
        await this.assetDBHelper.updateInvestmentAsset(asset);
        
        // 重新加载数据
        this.loadData();
        
        // 清空输入
        this.currentPrice = '';
        this.selectedAssetIndex = -1;
      } else {
        promptAction.showToast({
          message: '行情保存失败',
          duration: 2000
        });
      }
    } catch (error) {
      const err = error as ErrorInfo;
      console.error('保存行情失败', err);
      promptAction.showToast({
        message: `保存行情失败: ${err.message || '未知错误'}`,
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }
  
  // 格式化涨跌额
  formatChangeAmount(amount: number): string {
    return amount >= 0 ? `+${amount.toFixed(2)}` : `${amount.toFixed(2)}`;
  }
  
  // 格式化涨跌幅
  formatChangePercent(percent: number): string {
    return percent >= 0 ? `+${percent.toFixed(2)}%` : `${percent.toFixed(2)}%`;
  }
  
  // 获取涨跌颜色
  getChangeColor(change: number): string {
    return change > 0 ? '#f44336' : change < 0 ? '#4caf50' : '#999999';
  }

  // 显示资产类型选择弹窗
  showAssetSelection(): void {
    const dialogController = new CustomDialogController({
      builder: SelectionDialog({
        title: '选择标的',
        options: this.assets.map((asset, index) => {
          const v: SelectOption = {
            value: index + "",
            text: `${asset.name}(${asset.code})`
          };
          return v;
        }),
        onSelect: (value) => {
          this.selectedAssetIndex = parseInt(value);
          dialogController.close();
        }
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });
    dialogController.open();
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
        
        Text('市场行情')
          .fontSize(18)
          .fontWeight(500)
          .margin({ left: 16 })
        
        Blank()
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      
      // 行情录入表单
      Column() {
        Row() {
          Text('录入最新行情')
            .fontSize(16)
            .fontWeight(500)
            .margin({ top: 16, bottom: 8 })
        }
        
        Row() {
          Text('选择资产:')
            .fontSize(16)
            .fontColor('#333333')
            .width('30%')
            .padding({ right: 16})
          
          Text(this.selectedAssetIndex >= 0 ? this.assetOptions[this.selectedAssetIndex].text : '请选择资产')
            .backgroundColor('#f5f5f5')
            .fontColor('#333333')
            .borderRadius(4)
            .height(40)
            .width('70%')
            .onClick(() => {
              this.showAssetSelection()
            })
        }
        .width('100%')
        .margin({ top: 16 })
        
        Row() {
          Text('当前价格:')
            .fontSize(16)
            .fontColor('#666666')
            .width('30%')
          
          TextInput({ placeholder: '请输入当前价格', text: this.currentPrice })
            .width('70%')
            .height(40)
            .backgroundColor('#F5F5F5')
            .borderRadius(4)
            .padding({ left: 10, right: 10 })
            .type(InputType.NUMBER_DECIMAL)
            .onChange((value: string) => {
              this.currentPrice = value;
            })
        }
        .width('100%')
        .margin({ top: 16 })
        
        Button({
          type: ButtonType.Capsule
        }) {
          Row() {
            if (this.isLoading) {
              LoadingProgress()
                .width(24)
                .height(24)
                .color(Color.White)
                .margin({ right: 10 })
            }
            
            Text('保存行情')
              .fontSize(16)
              .fontColor(Color.White)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .height(44)
        .backgroundColor('#4fc08d')
        .margin({ top: 24 })
        .enabled(!this.isLoading)
        .onClick(() => {
          this.saveQuote();
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      
      // 行情列表
      Column() {
        Text('当前行情数据')
          .fontSize(16)
          .fontWeight(500)
          .margin({ top: 24, bottom: 8 })
        
        if (this.isLoading) {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#4fc08d')
            .margin({ top: 40 })
        } else if (this.quotes.length === 0) {
          Column() {
            Image($r('app.media.ic_empty'))
              .width(100)
              .height(100)
              .margin({ top: 30 })
            
            Text('暂无行情数据')
              .fontSize(16)
              .fontColor('#999999')
              .margin({ top: 16 })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.quotes, (quote: MarketQuoteModel) => {
              ListItem() {
                Row() {
                  Column() {
                    Text(quote.name)
                      .fontSize(16)
                      .fontWeight(500)
                    
                    Text(quote.code)
                      .fontSize(14)
                      .fontColor('#999999')
                      .margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .width('40%')
                  
                  Column() {
                    Text(quote.currentPrice.toFixed(2))
                      .fontSize(16)
                      .fontWeight(500)
                    
                    Text(this.formatChangeAmount(quote.changeAmount))
                      .fontSize(14)
                      .fontColor(this.getChangeColor(quote.changeAmount))
                      .margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.End)
                  .width('30%')
                  
                  Column() {
                    Text(this.formatChangePercent(quote.changePercent))
                      .fontSize(16)
                      .fontWeight(500)
                      .fontColor(this.getChangeColor(quote.changePercent))
                    
                    Text(new Date(quote.updateTime).toLocaleString())
                      .fontSize(12)
                      .fontColor('#999999')
                      .margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.End)
                  .width('30%')
                }
                .width('100%')
                .padding({ top: 12, bottom: 12 })
              }
              .onClick(() => {
                // 点击项目自动选择对应的资产
                const assetIndex = this.assets.findIndex(asset => asset.code === quote.code);
                if (assetIndex >= 0) {
                  this.selectedAssetIndex = assetIndex;
                  this.currentPrice = quote.currentPrice.toString();
                }
              })
            })
          }
          .width('100%')
          .divider({ strokeWidth: 1, color: '#EEEEEE', startMargin: 16, endMargin: 16 })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
