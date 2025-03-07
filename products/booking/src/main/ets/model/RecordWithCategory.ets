import { CategoryModel } from './CategoryModel';
import { RecordModel } from './RecordModel';
import { BookingConstants } from '../constants/BookingConstants';

/**
 * 带有类别信息的记录数据模型
 */
export class RecordWithCategory extends RecordModel {
  /**
   * 类别信息
   */
  category: CategoryModel;
  
  /**
   * 类别名称
   */
  name: string = '';
  
  /**
   * 类别图标
   */
  icon: Resource = $r(BookingConstants.EMPTY_ICON);
  
  constructor(record: RecordModel, category: CategoryModel) {
    super(record.type, record.categoryId, record.amount, 
      record.description, record.recordTime, record.accountBookId,
      record.createTime, record.id);
    this.category = category;
    
    if (category) {
      this.name = category.name;
      this.icon = category.icon;
    }
  }
}
