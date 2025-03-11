import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, catchError, firstValueFrom, of } from 'rxjs';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';


export interface WorkPackageHours {
  planned_h: number;
}

export interface WorkLoads {
  [date: string]: {
    planned_h_total: number;
    work_packages: {
      [workPackageId: string]: WorkPackageHours;
    };
  };
}

export interface IdMapping {
  work_package_id: number;
  resource_booking_id: number;
  hours_per_day: number;
  hours: number[];
}

export interface UserWorkLoads {
  user_id: number;
  id_mappings: IdMapping[];
  work_loads: WorkLoads;
}

export type ResourceBookingLoadResponse = UserWorkLoads[];

export interface ResourceBookingResponse {
  id: number;
  project_id: number;
  assigned_to_id: number;
  work_package_id: number;
  author_id: number;
  start_date: string;
  end_date: string;
  hours_per_day: number;
  notes: string;
  created_at: string;
  updated_at: string;
  hours: number[];
}

@Injectable({
  providedIn: 'root'
}) 
export class ResourceBookingService {
  private apiUrl = 'http://localhost:4200/resource_bookings';

  // 使用BehaviorSubject保持最新状态
  private newBookingSubject = new BehaviorSubject<any>(null);
  public newBooking$ = this.newBookingSubject.asObservable();

  // 更新数据方法
  private updateBookingSubject = new BehaviorSubject<any>(null);
  public  updateBooking$ = this.updateBookingSubject.asObservable();
  
  constructor(private http: HttpClient, private toastService: ToastService) {}

  getUserWorkLoads(userIds: number[], dateFrom: string, dateTo: string): Observable<ResourceBookingLoadResponse> {
    const params = {
      user_ids: userIds.join(','),
      date_from: dateFrom,
      date_to: dateTo
    };

    return this.http.get<ResourceBookingLoadResponse>(`${this.apiUrl}_loads`, { params });
  }


  public async getResourceBooking(id: number): Promise<ResourceBookingResponse | null> {
    try {
      const response = await firstValueFrom(
        this._getResourceBooking(id).pipe(
          catchError((error) => {
            console.error('Error fetching resource booking:', error);
            this.toastService.addError('Failed to fetch resource booking');
            return of(null);
          })
        )
      );
      return response;
    } catch (error) {
      console.error('Error fetching resource booking:', error);
      this.toastService.addError('Failed to fetch resource booking');
      return null;
    }
  }
  
  public async createResourceBooking(newResourceBooking: any): Promise<ResourceBookingResponse | null> {
    // 入参检查
   // if (!newResourceBooking.project_id || !newResourceBooking.assigned_to_id || !newResourceBooking.work_package_id || !newResourceBooking.author_id || !newResourceBooking.start_date || !newResourceBooking.end_date || !newResourceBooking.hours) {
    if (  !newResourceBooking.work_package_id || !newResourceBooking.start_date || !newResourceBooking.end_date || !newResourceBooking.hours) {
      console.error('Invalid new resource booking parameters', newResourceBooking);
        this.toastService.addError('Invalid parameters for creating resource booking');
        return null;
    }
    newResourceBooking.hours = newResourceBooking.hours.map((entry: { date: string, hours: number }) => entry.hours);

    console.log('begin post resource booking', newResourceBooking);
    try {
      const response = await firstValueFrom(
        this._createResourceBooking(newResourceBooking).pipe(
          catchError((error) => {
            console.error('Error creating resource booking:', error);
            this.toastService.addError('Failed to create resource booking');
            return of(null);
          })
        )
      );
      this.newBookingSubject.next(response);  //更新最新数据
      return response;
    } catch (error) {
      console.error('Error creating resource booking:', error);
      this.toastService.addError('Failed to create resource booking');
      return null;
    }
  }
  
  public async updateResourceBooking(id: number, updatedResourceBooking: any): Promise<ResourceBookingResponse | null> {
    // 入参检查
    if ( !updatedResourceBooking.hours) {
      console.error('Invalid updated resource booking parameters');
      this.toastService.addError('Invalid parameters for updating resource booking');
      return null;
    }
  
    try {
      const response = await firstValueFrom(
        this._updateResourceBooking(id, updatedResourceBooking).pipe(
          catchError((error) => {
            console.error('Error updating resource booking:', error);
            this.toastService.addError('Failed to update resource booking');
            return of(null);
          })
        )
      );
      this.updateBookingSubject.next(response);  //更新最新数据      
      return response;
    } catch (error) {
      console.error('Error updating resource booking:', error);
      this.toastService.addError('Failed to update resource booking');
      return null;
    }
  }

  private _getResourceBooking(id: number): Observable<ResourceBookingResponse> {
    return this.http.get<ResourceBookingResponse>(`${this.apiUrl}/${id}`);
  }

  private _createResourceBooking(resourceBooking: Omit<ResourceBookingResponse, 'id' | 'created_at' | 'updated_at'>): Observable<ResourceBookingResponse> {
    return this.http.post<ResourceBookingResponse>(this.apiUrl, resourceBooking);
  }

  private _updateResourceBooking(id: number, resourceBooking: Partial<Omit<ResourceBookingResponse, 'id' | 'created_at' | 'updated_at'>>): Observable<ResourceBookingResponse> {
    return this.http.put<ResourceBookingResponse>(`${this.apiUrl}/${id}`, resourceBooking);
  }
}



// class ResourceBookingResource extends HalResource {
//   public $embedded: {
//     loads: ResourceBookingResponse[];
//   };

//   public $links: {
//     loads: HalLinkInterface;
//   };

//   public $initialize(source:any) {
//     super.$initialize(source);
//     this.$embedded.loads = source.loads;
//   }

//   public get $isHal():boolean {
//     returntrue;
//   }
// }