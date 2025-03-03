/**
 * 滑动操作组件定义
 */
export interface SwipeAction {
  /**
   * 操作图标
   */
  icon: Resource;
  
  /**
   * 点击执行的操作
   */
  action: () => void;
  
  /**
   * 背景颜色
   */
  color: string;
};
