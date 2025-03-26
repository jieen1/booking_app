/**
 * 投资品种列表组件
 */
import router from '@ohos.router';
import { InvestmentAssetModel } from '../../model/InvestmentAssetModel';
import { CustomAlertDialog } from '../CustomDialog';
import { InvestmentAssetDBHelper } from '../../database/InvestmentAssetDBHelper';

@Component
export struct InvestmentAssetList {
  @Prop assets: InvestmentAssetModel[] = [];
  @Prop bookId: number = 0;
  onRefresh?: () => void;
  @State sortBy: string = 'profit';
  @State sortOrder: string = 'desc';
  @State currentAssetId: number = -1;
  private assetHelper = InvestmentAssetDBHelper.getInstance();


  // 自定义对话框控制器
  private deleteDialogController: CustomDialogController = new CustomDialogController({
    builder: CustomAlertDialog({
      title: '确认删除',
      message: '确定要删除这条记录吗？',
      cancelText: '取消',
      confirmText: '删除',
      onCancel: () => {
        console.info('取消删除');
      },
      onConfirm: async () => {
        if (this.currentAssetId != -1) {
          await this.deleteAsset(this.currentAssetId);
        }
      }
    }),
    alignment: DialogAlignment.Center,
    autoCancel: true,
    customStyle: true
  });

  async deleteAsset(currentAssetId: number) {
      try {
        await this.assetHelper.deleteAsset(currentAssetId);
        this.onRefresh?.();
      } catch (error) {
        console.error(`删除记录失败: ${error}`);
      }
  }
  
  build() {
    Column() {
      // 排序选项
      Row() {
        Text('排序:')
          .fontSize(14)
          .fontColor('#666666')
        
        Row() {
          Text('收益率')
            .fontSize(14)
            .fontColor(this.sortBy === 'profit' ? '#4fc08d' : '#666666')
            .fontWeight(this.sortBy === 'profit' ? FontWeight.Bold : FontWeight.Normal)
        }
        .padding({ left: 8, right: 8 })
        .backgroundColor(this.sortBy === 'profit' ? 'rgba(79, 192, 141, 0.1)' : 'transparent')
        .borderRadius(4)
        .margin({ left: 8 })
        .onClick(() => {
          if (this.sortBy === 'profit') {
            this.sortOrder = this.sortOrder === 'desc' ? 'asc' : 'desc';
          } else {
            this.sortBy = 'profit';
            this.sortOrder = 'desc';
          }
        })
        
        Row() {
          Text('持仓金额')
            .fontSize(14)
            .fontColor(this.sortBy === 'amount' ? '#4fc08d' : '#666666')
            .fontWeight(this.sortBy === 'amount' ? FontWeight.Bold : FontWeight.Normal)
        }
        .padding({ left: 8, right: 8 })
        .backgroundColor(this.sortBy === 'amount' ? 'rgba(79, 192, 141, 0.1)' : 'transparent')
        .borderRadius(4)
        .margin({ left: 8 })
        .onClick(() => {
          if (this.sortBy === 'amount') {
            this.sortOrder = this.sortOrder === 'desc' ? 'asc' : 'desc';
          } else {
            this.sortBy = 'amount';
            this.sortOrder = 'desc';
          }
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      
      List() {
        ForEach(this.getSortedAssets(), (asset: InvestmentAssetModel) => {
          ListItem() {
            this.AssetListItem(asset)
          }
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .onClick(() => {
            // 跳转到投资品种详情页
            router.pushUrl({
              url: 'pages/investment/AssetDetailPage',
              params: {
                bookId: this.bookId,
                assetId: asset.id
              }
            });
          })
          .swipeAction({
            end: {
              builder: this.itemEnd(asset),
              onAction: () => {
                // 删除该操作，使用按钮点击触发相应功能
              },
              actionAreaDistance: 120
            }
          })
        })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
  
  getSortedAssets(): InvestmentAssetModel[] {
    if (!this.assets || this.assets.length === 0) {
      return [];
    }
    
    return [...this.assets].sort((a, b) => {
      let compareValueA = 0;
      let compareValueB = 0;
      
      if (this.sortBy === 'profit') {
        compareValueA = a.getProfitRate();
        compareValueB = b.getProfitRate();
      } else if (this.sortBy === 'amount') {
        compareValueA = a.getCurrentValue();
        compareValueB = b.getCurrentValue();
      }
      
      if (this.sortOrder === 'desc') {
        return compareValueB - compareValueA;
      } else {
        return compareValueA - compareValueB;
      }
    });
  }

  @Builder itemEnd(asset: InvestmentAssetModel) {
    Row() {
      Column() {
        Image($r('app.media.ic_delete_cartoon_new'))
          .width(28)
          .height(28)
        Text('删除')
          .fontSize(12)
          .fontColor($r('app.color.TEXT_PRIMARY_COLOR'))
      }
      .width(56)
      .height(60)
      .borderRadius(12)
      .backgroundColor($r('app.color.BG_COLOR_SECONDARY'))
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        // 设置当前记录
        this.currentAssetId = asset.id??-1;
        // 显示删除确认对话框
        this.deleteDialogController.open();
      })
    }
    .width(120)
    .height(200)
    .justifyContent(FlexAlign.SpaceEvenly)
    .margin({bottom: 8})
  }
  
  @Builder
  AssetListItem(asset: InvestmentAssetModel) {
    Row() {
      Column() {
        Row() {
          Text(asset.name)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
          
          Text(asset.code)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ left: 8 })
        }
        .width('100%')
        
        Text(`持有 ${asset.quantity} 股 | 现价 ¥${asset.currentPrice.toFixed(2)} | 成本 ¥${asset.purchasePrice.toFixed(2)}`)
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      Column() {
        Text(`¥${asset.getCurrentValue().toFixed(2)}`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
        
        Row() {
          Text(`${asset.getProfit() >= 0 ? '+' : ''}${asset.getProfit().toFixed(2)}`)
            .fontSize(12)
            .fontColor(asset.getProfit() >= 0 ? '#ff5722' : '#4caf50')
          
          Text(`(${asset.getProfitRate() >= 0 ? '+' : ''}${asset.getProfitRate().toFixed(2)}%)`)
            .fontSize(12)
            .fontColor(asset.getProfitRate() >= 0 ? '#ff5722' : '#4caf50')
            .margin({ left: 4 })
        }
        .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(12)
    .borderRadius(8)
    .backgroundColor(Color.White)
  }
}
