import { ID } from '@datorama/akita';
import {
  action,
  props,
} from 'ts-action';

export const resourcePlannerEventRemoved = action(
  '[Resource planner] Event removed from resource planner',
  props<{ workPackage:ID }>(),
);

export const resourcePlannerEventAdded = action(
  '[Resource planner] External event added to the resource planner',
  props<{ workPackage:ID }>(),
);

export const resourcePlannerPageRefresh = action(
  '[Resource planner] Refresh resource planner page due to external param changes',
  props<{ showLoading:boolean }>(),
);
