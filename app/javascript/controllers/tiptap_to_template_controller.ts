import { Controller } from '@hotwired/stimulus';

export class TiptapToTemplateController extends Controller {
  static targets = ['output', 'trigger'];

  declare readonly outputTarget: HTMLElement;
  declare readonly triggerTarget: HTMLButtonElement;
  declare template: HTMLElement | null;

  connect() {
    this.triggerTarget.addEventListener('click', this.handleClick.bind(this));

    this.template = this.element.querySelector('.tiptap.ProseMirror p');
  }

  handleClick() {
    if (this.template) {
      this.outputTarget.innerHTML = this.template.innerHTML;
    }
  }
}
