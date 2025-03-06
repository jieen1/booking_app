/**
 * 记账分类数据模型
 */
export class CategoryModel {
  /**
   * 分类ID
   */
  id?: number;

  /**
   * 分类类型: 1-收入, 2-支出
   */
  type: number;

  /**
   * 分类名称
   */
  name: string;

  /**
   * 分类图标标识符或资源对象
   */
  icon: Resource;

  /**
   * 创建时间
   */
  createTime: number;
  
  constructor(type: number, name: string, icon: Resource, id?: number) {
    this.id = id;
    this.type = type;
    this.name = name;
    this.icon = icon;
    this.createTime = new Date().getTime();
  }
}

export interface DuplicateCategoryGroup {
  keepId: number;
  type: number;
  name: string;
  count: number;
}

/**
 * 分类选项接口
 */
export interface CategoryOption {
  type: number;
  name: string;
  icon: string;
}