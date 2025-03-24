/**
 * 投资账本转账页面
 */
import router from '@ohos.router';
import { InvestmentBookModel } from '../../model/InvestmentBookModel';
import { InvestmentBookDBHelper } from '../../database/InvestmentBookDBHelper';
import { InvestmentTransactionDBHelper } from '../../database/InvestmentTransactionDBHelper';
import { TransactionType, InvestmentTransactionModel } from '../../model/InvestmentTransactionModel';
import promptAction from '@ohos.promptAction';

/**
 * 下拉框选项接口
 */
interface SelectOption {
  value: string;
  text: string;
}

// 路由参数接口
interface RouteParams {
  bookId: number;
  bookName: string;
}

@Entry
@Component
export struct InvestmentTransferPage {
  @State sourceBookId: number = -1;
  @State sourceBookName: string = '';
  @State targetBookId: number = -1;
  @State amount: number = 0;
  @State remark: string = '';
  @State date: string = this.formatDate(new Date());
  @State isSubmitting: boolean = false;
  @State investmentBooks: InvestmentBookModel[] = [];
  @State bookOptions: SelectOption[] = [];
  
  /**
   * 页面初始化
   */
  aboutToAppear(): void {
    // 获取路由参数
    const params = router.getParams() as RouteParams;
    if (params) {
      this.sourceBookId = params.bookId;
      this.sourceBookName = params.bookName;
    }
    
    // 加载投资账本列表
    this.loadInvestmentBooks();
  }
  
  /**
   * 格式化日期为字符串
   * @param date 日期对象
   * @returns 格式化后的日期字符串
   */
  private formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }
  
  /**
   * 加载投资账本列表
   */
  private async loadInvestmentBooks(): Promise<void> {
    try {
      const bookHelper = InvestmentBookDBHelper.getInstance();
      let books = await bookHelper.getAllInvestmentBooks();
      
      // 排除当前账本
      this.investmentBooks = books.filter(book => book.id !== this.sourceBookId);
      
      // 为Select组件准备选项数据
      this.bookOptions = this.investmentBooks.map(book => {
        // 使用明确的类型定义
        const option: SelectOption = {
          value: book.id?.toString() || '',
          text: book.name
        };
        return option;
      });
    } catch (error) {
      console.error('加载投资账本列表失败', error);
      promptAction.showToast({ message: '加载账本失败，请重试', duration: 2000 });
    }
  }
  
  /**
   * 保存转账交易
   */
  private async saveTransfer(): Promise<void> {
    if (this.targetBookId === -1) {
      promptAction.showToast({ message: '请选择目标账本', duration: 2000 });
      return;
    }
    
    if (this.amount <= 0) {
      promptAction.showToast({ message: '请输入有效的金额', duration: 2000 });
      return;
    }
    
    try {
      this.isSubmitting = true;
      
      // 创建两笔转账记录
      const transactionHelper = InvestmentTransactionDBHelper.getInstance();

      // 转账日期
      const transferDate = new Date(this.date).getTime();
      
      // 1. 从源账本转出（记录类型为转出）
      const sourceTransaction = new InvestmentTransactionModel(
        this.sourceBookId,
        0, // 转账不需要指定资产
        TransactionType.TRANSFER_OUT,
        1, // 转账价格固定为1
        this.amount,
        this.amount,
        0, // 无手续费
        this.targetBookId,
        this.remark,
        transferDate
      );
      
      // 2. 向目标账本转入（记录类型为转入）
      const targetTransaction = new InvestmentTransactionModel(
        this.targetBookId,
        0, // 转账不需要指定资产
        TransactionType.TRANSFER_IN,
        1, // 转账价格固定为1
        this.amount,
        this.amount,
        0, // 无手续费
        this.sourceBookId,
        this.remark,
        transferDate
      );
      
      // 创建交易记录
      const sourceTransactionId = await transactionHelper.createTransaction(sourceTransaction);
      const targetTransactionId = await transactionHelper.createTransaction(targetTransaction);
      
      if (sourceTransactionId > 0 && targetTransactionId > 0) {
        // 3. 更新源账本和目标账本的余额
        await this.updateBookBalance(this.sourceBookId, -this.amount);
        await this.updateBookBalance(this.targetBookId, this.amount);
        
        promptAction.showToast({
          message: '转账成功',
          duration: 2000
        });
        
        // 返回上一页
        setTimeout(() => {
          router.back();
        }, 1000);
      }
    } catch (error) {
      console.error('保存转账交易失败', error);
      promptAction.showToast({
        message: `转账失败: ${error.message || '未知错误'}`,
        duration: 3000
      });
    } finally {
      this.isSubmitting = false;
    }
  }
  
  /**
   * 更新账本余额
   * @param bookId 账本ID
   * @param amount 变动金额
   */
  private async updateBookBalance(bookId: number, amount: number): Promise<void> {
    try {
      const bookHelper = InvestmentBookDBHelper.getInstance();
      const book = await bookHelper.getInvestmentBookById(bookId);
      if (book && book.id) {
        const newBalance = (book.balance || 0) + amount;
        book.balance = newBalance;
        await bookHelper.updateInvestmentBook(book);
      }
    } catch (error) {
      console.error(`更新账本余额失败, bookId=${bookId}`, error);
      throw new Error(`更新账本余额失败: ${error.message}`);
    }
  }
  
  build() {
    Column() {
      // 标题栏
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .margin({ right: 16 })
          .onClick(() => {
            router.back();
          })
        Text('账本转账')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
      .padding(16)
      
      // 内容区域
      Scroll() {
        Column() {
          Column() {
            // 源账本
            Row() {
              Text('转出账本:')
                .fontSize(16)
                .fontColor('#666666')
                .width('30%')
              Text(this.sourceBookName)
                .fontSize(16)
                .fontColor('#333333')
                .width('70%')
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .margin({ bottom: 12 })
            
            // 目标账本
            Row() {
              Text('转入账本:')
                .fontSize(16)
                .fontColor('#666666')
                .width('30%')
              Column() {
                if (this.investmentBooks.length > 0) {
                  Select(this.bookOptions)
                    .selected(this.investmentBooks.findIndex(book => book.id === this.targetBookId))
                    .value(this.targetBookId.toString())
                    .backgroundColor('#00000000')
                    .width('100%')
                    .onSelect((index: number) => {
                      if (index >= 0 && index < this.investmentBooks.length) {
                        this.targetBookId = this.investmentBooks[index].id || -1;
                      }
                    })
                } else {
                  Text('没有可用的目标账本')
                    .fontSize(16)
                    .fontColor('#999999')
                }
              }
              .width('70%')
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .margin({ bottom: 12 })
            
            // 转账金额
            Row() {
              Text('转账金额:')
                .fontSize(16)
                .fontColor('#666666')
                .width('30%')
              TextInput({ text: this.amount.toString() })
                .type(InputType.Number)
                .fontSize(16)
                .backgroundColor('#00000000')
                .width('70%')
                .onChange((value: string) => {
                  this.amount = parseFloat(value) || 0;
                })
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .margin({ bottom: 12 })
            
            // 转账日期
            Row() {
              Text('转账日期:')
                .fontSize(16)
                .fontColor('#666666')
                .width('30%')
              DatePicker({
                start: new Date('2000-01-01'),
                end: new Date('2030-12-31'),
                selected: new Date(this.date)
              })
                .onChange((value: DatePickerResult) => {
                  // 将DatePickerResult转换为Date对象
                  const date = new Date(`${value.year}-${value.month}-${value.day}`);
                  this.date = this.formatDate(date);
                })
                .width('70%')
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
              TextInput({ text: this.remark })
                .fontSize(16)
                .backgroundColor('#00000000')
                .width('70%')
                .onChange((value: string) => {
                  this.remark = value;
                })
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .margin({ bottom: 12 })
            
            // 保存按钮
            Button({
              type: ButtonType.Normal,
              stateEffect: true
            }) {
              Text('确认转账')
                .fontColor('#FFFFFF')
                .fontSize(16)
            }
            .onClick(() => this.saveTransfer())
            .width('100%')
            .height(50)
            .backgroundColor(this.isSubmitting ? '#999999' : '#4A7AFF')
            .borderRadius(25)
            .enabled(!this.isSubmitting)
            .margin({ top: 24 })
          }
          .width('100%')
          .padding(16)
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
