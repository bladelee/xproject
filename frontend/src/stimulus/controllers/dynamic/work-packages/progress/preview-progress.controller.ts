/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2024 the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { Controller } from '@hotwired/stimulus';
import { debounce } from 'lodash';
import Idiomorph from 'idiomorph/dist/idiomorph.cjs';

interface TurboBeforeFrameRenderEventDetail {
  render:(currentElement:HTMLElement, newElement:HTMLElement) => void;
}

export default class PreviewProgressController extends Controller {
  static targets = [
    'form', 'progressInput',
  ];

  declare readonly progressInputTargets:HTMLInputElement[];
  declare readonly formTarget:HTMLFormElement;

  private debouncedPreview:(event:Event) => void;
  private frameMorphRenderer:(event:CustomEvent<TurboBeforeFrameRenderEventDetail>) => void;

  connect() {
    this.debouncedPreview = debounce((event:Event) => { void this.preview(event); }, 100);
    // TODO: Ideally morphing in this single controller should not be necessary.
    // Turbo supports morphing, by adding the <turbo-frame refresh="morph"> attribute.
    // However, it has a bug, and it doesn't morphs when reloading the frame via javascript.
    // See https://github.com/hotwired/turbo/issues/1161 . Once the issue is solved, we can remove
    // this code and just use <turbo-frame refresh="morph"> instead.
    this.frameMorphRenderer = (event:CustomEvent<TurboBeforeFrameRenderEventDetail>) => {
      event.detail.render = (currentElement:HTMLElement, newElement:HTMLElement) => {
        Idiomorph.morph(currentElement, newElement, { ignoreActiveValue: true });
      };
    };

    this.progressInputTargets.forEach((target) => {
      target.addEventListener('input', this.debouncedPreview);
    });

    const turboFrame = this.formTarget.closest('turbo-frame') as HTMLFrameElement;
    turboFrame.addEventListener('turbo:before-frame-render', this.frameMorphRenderer);
  }

  disconnect() {
    this.progressInputTargets.forEach((target) => target.removeEventListener('input', this.debouncedPreview));
    const turboFrame = this.formTarget.closest('turbo-frame') as HTMLFrameElement;
    turboFrame.removeEventListener('turbo:before-frame-render', this.frameMorphRenderer);
  }

  async preview(event:Event) {
    const field = event.target as HTMLInputElement;
    const form = this.formTarget;
    const formData = new FormData(form) as unknown as undefined;
    const formParams = new URLSearchParams(formData);
    const wpParams = [
      ['work_package[remaining_hours]', formParams.get('work_package[remaining_hours]') || ''],
      ['work_package[estimated_hours]', formParams.get('work_package[estimated_hours]') || ''],
      ['work_package[status_id]', formParams.get('work_package[status_id]') || ''],
      ['field', field.name ?? 'estimatedTime'],
      ['work_package[remaining_hours_touched]', formParams.get('work_package[remaining_hours_touched]') || ''],
      ['work_package[estimated_hours_touched]', formParams.get('work_package[estimated_hours_touched]') || ''],
      ['work_package[status_id_touched]', formParams.get('work_package[status_id_touched]') || ''],
    ];

    const wpPath = this.ensureValidPathname(form.action);

    const editUrl = `${wpPath}/edit?${new URLSearchParams(wpParams).toString()}`;
    const turboFrame = this.formTarget.closest('turbo-frame') as HTMLFrameElement;

    if (turboFrame) {
      turboFrame.src = editUrl;
    }
  }

  // Ensures that on create forms, there is an "id" for the un-persisted
  // work package when sending requests to the edit action for previews.
  private ensureValidPathname(formAction:string):string {
    const wpPath = new URL(formAction);

    if (wpPath.pathname.endsWith('/work_packages/progress')) {
      // Replace /work_packages/progress with /work_packages/new/progress
      wpPath.pathname = wpPath.pathname.replace('/work_packages/progress', '/work_packages/new/progress');
    }

    return wpPath.toString();
  }
}
