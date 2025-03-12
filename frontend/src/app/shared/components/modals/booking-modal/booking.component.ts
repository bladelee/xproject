import { Component, ElementRef, Inject, ViewChild, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { ChangeDetectorRef } from '@angular/core';
import { ResourceBookingService } from 'core-app/features/resource-planner/resource-planner/resource-booking/resource-booking.service';
import { t } from '@fullcalendar/resource/internal-common';

interface DailyBooking {
  date: string;
  hours: number;
}

@Component({
  selector: 'app-booking',
  standalone: true,
  imports: [CommonModule, FormsModule],
  // imports: [CommonModule],
  templateUrl: './booking.component.html',
  styleUrls: ['./booking.component.css'],
})
export class BookingComponent extends OpModalComponent {

  @Input() startDate!: string;
  @Input() endDate!: string;
  @Input() totalPlannedHours!: number;
  @Input() defaultDailyHours?: number | null; // 新增：每日默认分配工时
  @Input() existingBookings?: number[]; // 新增：每日工时分配明细
  
  @Output() create = new EventEmitter<{
    defaultHours: number | null;
    bookings: DailyBooking[];
  }>();
  @Output() update = new EventEmitter<{
    defaultHours: number | null;
    bookings: DailyBooking[];
  }>();
  @Output() cancelBooking = new EventEmitter<void>();

  @ViewChild('bookingForm', { static: false }) bookingForm: ElementRef;

  public text = {
    title: '工时预订',
    label_start_date: '开始日期',
    // label_start_date: 'abc',
    label_end_date: '结束日期',
    label_total_hours: '计划工时',
    label_default_hours_per_day: '每日默认工时',
    button_save: '保存',
    button_cancel: '取消',
    label_daily_bookings: '预定xx'
  };

  defaultHoursPerDay = 8;
  dailyBookings: DailyBooking[] = [];
  isEditMode = false;

  private workPackage_id: string;
  private bookingResourceId: number|null;
  private assigned_to_id: number|null;
  private project_id: number | null;

  ngOnInit() {
    // 判断是否为编辑模式
    this.isEditMode =  this.defaultDailyHours !== undefined && this.defaultDailyHours !== null || 
      (this.existingBookings?.length ?? 0) > 0;
    
    if (this.isEditMode && this.existingBookings) {
      // 编辑模式：使用现有数据
      this.dailyBookings = this.generateDailyBookings(this.startDate, this.endDate, this.existingBookings);
      if (this.defaultDailyHours) {
        this.defaultHoursPerDay = this.defaultDailyHours;
      } else {
        // 如果没有默认工时，检查是否所有非零工时都相等
        this.updateDefaultHoursFromBookings();
      }
    } else {
      // 新建模式：初始化数据
      this.initializeDailyBookings();
      this.distributeHours();
    }
  }

  constructor(
    readonly elementRef: ElementRef,
    @Inject(OpModalLocalsToken) public locals: OpModalLocalsMap,
    readonly cdRef: ChangeDetectorRef,
    private resourceBookingService: ResourceBookingService,
  ) {
    super(locals, cdRef, elementRef);
    this.startDate = this.locals.startDate as string
    this.endDate = this.locals.endDate  as string
    this.totalPlannedHours = this.locals.totalPlannedHours as number;
    this.workPackage_id = this.locals.work_package_id as string;
    this.bookingResourceId = this.locals.resource_booking_id as number|null; 
    this.defaultDailyHours = this.locals.housrs_per_day as number|null; 
    this.existingBookings = this.locals.dailyPlannedHours as number[]; 
    this.assigned_to_id = this.locals.assigned_to_id as number|null;
    this.project_id = this.locals.project_id as number|null;

    console.log('this.locals====',this.locals);
  }

  private generateDailyBookings(startDate: string, endDate: string, existingBookings: number[]): DailyBooking[] {
    const dailyBookings: DailyBooking[] = [];
    // 将起始日期和结束日期转换为 Date 对象
    let currentDate = new Date(startDate);
    const end = new Date(endDate);
    let index = 0;

    // 循环从起始日期到结束日期
    while (currentDate <= end) {
      // 格式化当前日期为字符串
      const dateString = currentDate.toISOString().split('T')[0];
      // 从 existingBookings 中获取对应的小时数，如果没有则默认为 0
      const hours = index < existingBookings.length ? existingBookings[index] : 0;
      // 创建一个新的 DailyBooking 对象
      const dailyBooking: DailyBooking = {
        date: dateString,
        hours: hours
      };
      // 将新的 DailyBooking 对象添加到数组中
      dailyBookings.push(dailyBooking);
      // 日期加一天
      currentDate.setDate(currentDate.getDate() + 1);
      index++;
    }

    return dailyBookings;
  }



  private initializeDailyBookings() {
    const start = new Date(this.startDate);
    const end = new Date(this.endDate);
    this.dailyBookings = [];
    
    for (let date = new Date(start); date <= end; date.setDate(date.getDate() + 1)) {
      this.dailyBookings.push({
        date: date.toISOString().split('T')[0],
        hours: 0
      });
    }
  }

  // 计算允许的最大天数
  private getMaxAllowedDays(): number {
    const start = new Date(this.startDate);
    const end = new Date(this.endDate);
    const diffTime = Math.abs(end.getTime() - start.getTime());
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays + 1; // +1 是因为包含起始日期
  }

  // 检查是否可以添加更多天数
  canAddMoreDays(): boolean {
    const maxAllowedDays = this.getMaxAllowedDays();
    const lastBookingDate = new Date(this.dailyBookings[this.dailyBookings.length - 1].date);
    const endDate = new Date(this.endDate);
    
    // 检查当前天数是否已达到最大允许天数
    // 且最后一个预订日期是否未超过结束日期
    return this.dailyBookings.length < maxAllowedDays && 
           lastBookingDate < endDate;
  }

  // 添加下一天时也需要检查日期范围
  addNextDay() {
    if (this.canAddMoreDays()) {
      const lastDate = new Date(this.dailyBookings[this.dailyBookings.length - 1].date);
      const nextDate = new Date(lastDate);
      nextDate.setDate(nextDate.getDate() + 1);
      
      // 确保新添加的日期不超过结束日期
      if (nextDate <= new Date(this.endDate)) {
        this.dailyBookings.push({
          date: nextDate.toISOString().split('T')[0],
          hours: 1
        });
      }
    }
  }

  removeLastDay() {
    if (this.dailyBookings.length > 1) {
      this.dailyBookings.pop();
    }
  }

  distributeHours() {
   
    this.dailyBookings.forEach(booking => {
      booking.hours =  this.defaultHoursPerDay;
    });
  }

  get currentTotal(): number {
    const total = this.dailyBookings.reduce((sum, booking) => sum + booking.hours, 0);
    console.log('this.dailyBookings=',this.dailyBookings);
    console.log('currentTotal=',total);
    return total;
  }

  get isValidTotal(): boolean {
    return this.currentTotal > 0 ;
  }

  // 修改工时变更处理方法
  onHoursChange() {
    this.updateDefaultHoursStatus();
  }

  // 检查并更新默认工时状态
  private updateDefaultHoursStatus() {
    const nonZeroBookings = this.dailyBookings.filter(booking => booking.hours > 0);
    
    console.log('nonZeroBookings=',nonZeroBookings);

    // 检查是否有非零工时且不等于默认工时的记录
    const hasInconsistentHours = nonZeroBookings.some(
      booking => booking.hours !== this.defaultHoursPerDay
    );
    console.log('hasInconsistentHours=',hasInconsistentHours);

    if (hasInconsistentHours) {
      // 如果有不一致的工时，清空默认工时
      this.defaultHoursPerDay = 0;
    }
  }

  onCancel($event:Event) {
    this.cancelBooking.emit();
    this.closeMe();
  }

  // 根据现有预订更新默认工时
  private updateDefaultHoursFromBookings() {
    const nonZeroHours = this.dailyBookings
      .map(booking => booking.hours)
      .filter(hours => hours > 0);
    
    const allEqual = nonZeroHours.every(hours => hours === nonZeroHours[0]);
    if (allEqual && nonZeroHours.length > 0) {
      this.defaultHoursPerDay = nonZeroHours[0];
    } else {
      this.defaultHoursPerDay = 0; // 表示没有统一的默认工时
    }
  }

  // 检查是否所有非零工时都等于默认工时
  private checkDefaultHoursConsistency(): boolean {
    return this.dailyBookings
      .filter(booking => booking.hours > 0)
      .every(booking => booking.hours === this.defaultHoursPerDay);
  }

  onDefaultHoursChange(event: Event) {
    const input = event.target as HTMLInputElement;
    let value = parseInt(input.value);
    
    if (isNaN(value)) {
      value = 1;
    } else if (value < 1) {
      value = 1;
    } else if (value > 12) {
      value = 12;
    }
    
    this.defaultHoursPerDay = Number(value);
    this.distributeHours();
  }

  onSave($event:Event) {
    if (!this.isValidTotal) {
      return;
    }

    console.log('workPackage_id==', this.workPackage_id);
  
    const result = {
      defaultHours: this.defaultHoursPerDay || null, // 如果为0则发送null
      bookings: this.dailyBookings
    };
      
    if (this.isEditMode) {  // 如果是编辑模式，则发送更新请求
      this.update.emit(result);

      if (!this.bookingResourceId){
          console.error('bookingResourceId is null or undefined.');
          return;
      }

      const updatedResourceBooking = {
        work_package_id: this.workPackage_id,
        // hours_per_day: this.defaultHoursPerDay == 0 ? null : this.defaultHoursPerDay,
        hours_per_day: this.defaultHoursPerDay,
        hours: this.dailyBookings.map(booking => booking.hours)
      };

      this.resourceBookingService.updateResourceBooking(this.bookingResourceId, updatedResourceBooking)
        .then(updatedResourceBookingResponse => {
          if (updatedResourceBookingResponse) {
            console.log('Updated Resource Booking:', updatedResourceBookingResponse);
          }
        })
        .catch(error => {
          console.error('Error in bookingInit:', error);
        });      
    } else {
      this.create.emit(result);

      const newResourceBooking = {
        project_id: this.project_id,
        assigned_to_id: this.assigned_to_id ,
        work_package_id: this.workPackage_id,
        author_id: 4,
        start_date: this.startDate,
        end_date: this.endDate,
        hours_per_day: this.defaultHoursPerDay,
        notes: 'Some notes here',
        hours: this.dailyBookings
      };

      this.resourceBookingService.createResourceBooking(newResourceBooking)
        .then(createdResourceBooking => {
          if (createdResourceBooking) {
            console.log('Created Resource Booking:', createdResourceBooking);
          }
        })
        .catch(error => {
          console.error('Error in bookingInit:', error);
        });
    }
    this.closeMe();
  }

  //   onCancel($event:Event) {
  //   this.cancel.emit();
  //   this.closeMe();
  // }

  public onOpen(): void {
    this.bookingForm.nativeElement.focus();
  }

  public get afterFocusOn(): HTMLElement {
    return document.getElementById('booking-form') as HTMLElement;
  }
}

  // @Input() startDate: string = '';
  // @Input() endDate: string = '';
  // @Input() totalPlannedHours: number = 0;

  // @Output() save = new EventEmitter<DailyBooking[]>();
  // @Output() cancel = new EventEmitter<void>();

  // defaultHoursPerDay: number = 8;
  // dailyBookings: DailyBooking[] = [];

  // @ViewChild('bookingForm', { static: true }) bookingForm: ElementRef;

  // public text = {
  //   title: '工时预订',
  //   label_start_date: '开始日期',
  //   label_end_date: '结束日期',
  //   label_total_hours: '计划工时',
  //   label_default_hours_per_day: '每日默认工时',
  //   button_save: '保存',
  //   button_cancel: '取消',
  //   label_daily_bookings: '预定xx'
  
  // };

  // constructor(
  //   readonly elementRef: ElementRef,
  //   @Inject(OpModalLocalsToken) public locals: OpModalLocalsMap,
  //   readonly cdRef: ChangeDetectorRef,
  // ) {
  //   super(locals, cdRef, elementRef);
  // }

  // ngOnInit() {
  //   this.initializeDailyBookings();
  //   this.distributeHours();
  // }

  // private initializeDailyBookings() {
  //   const start = new Date(this.startDate);
  //   const end = new Date(this.endDate);

  //   for (let date = start; date <= end; date.setDate(date.getDate() + 1)) {
  //     this.dailyBookings.push({
  //       date: date.toISOString().split('T')[0],
  //       hours: 0,
  //     });
  //   }
  // }

  // distributeHours() {
  //   const daysCount = this.dailyBookings.length;
  //   const hoursPerDay = Math.min(
  //     this.defaultHoursPerDay,
  //     this.totalPlannedHours / daysCount
  //   );

  //   this.dailyBookings.forEach(booking => {
  //     booking.hours = hoursPerDay;
  //   });
  // }

  // get currentTotal(): number {
  //   return this.dailyBookings.reduce((sum, booking) => sum + booking.hours, 0);
  // }

  // get isValidTotal(): boolean {
  //   return Math.abs(this.currentTotal - this.totalPlannedHours) < 0.01;
  // }

  // onHoursChange() {
  //   // 可以在这里添加验证逻辑
  // }

  // onSave($event:Event) {
  //   if (this.isValidTotal) {
  //     this.save.emit(this.dailyBookings);
  //     this.closeMe();
  //   }
  // }

  // onCancel($event:Event) {
  //   this.cancel.emit();
  //   this.closeMe();
  // }

  // public onOpen(): void {
  //   this.bookingForm.nativeElement.focus();
  // }

  // public get afterFocusOn(): HTMLElement {
  //   return document.getElementById('booking-form') as HTMLElement;
  // }
// }