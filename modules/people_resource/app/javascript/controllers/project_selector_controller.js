import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "dropdown", 
    "selectedContainer", 
    "selectButton", 
    "checkbox"
  ]

  connect() {
    console.log("Project selector controller connected")
  }

  // 打开项目选择面板
  open(event) {
    event.preventDefault()
    this.dropdownTarget.style.display = 'block'
  }

  // 关闭项目选择面板
  close() {
    this.dropdownTarget.style.display = 'none'
  }

  // 确认选择
  confirm() {
    // 清除现有的隐藏字段
    const hiddenFields = this.selectedContainerTarget.querySelectorAll('input[type="hidden"]')
    hiddenFields.forEach(el => el.remove())
    
    // 获取所有选中的项目
    const selectedCheckboxes = this.checkboxTargets.filter(cb => cb.checked)
    const selectedProjects = []
    
    selectedCheckboxes.forEach(checkbox => {
      const id = checkbox.value
      const name = document.querySelector(`label[for="project_select_${id}"]`).textContent
      selectedProjects.push({id, name})
    })
    
    // 清除现有标签
    this.element.querySelectorAll('.project-tag').forEach(el => el.remove())
    
    // 添加新标签和隐藏字段
    selectedProjects.forEach(project => {
      const tag = document.createElement('span')
      tag.className = 'project-tag'
      tag.innerHTML = project.name + `<a href="#" class="remove-tag" data-id="${project.id}" data-action="click->project-selector#removeTag">×</a>`
      
      const hiddenField = document.createElement('input')
      hiddenField.type = 'hidden'
      hiddenField.name = 'project_ids[]'
      hiddenField.value = project.id
      
      this.selectedContainerTarget.insertBefore(tag, this.selectButtonTarget)
      this.selectedContainerTarget.appendChild(hiddenField)
    })
    
    // 隐藏下拉面板
    this.close()
  }

  // 删除标签
  removeTag(event) {
    event.preventDefault()
    const id = event.currentTarget.getAttribute('data-id')
    event.currentTarget.parentNode.remove()
    
    // 移除隐藏字段
    const hiddenField = this.selectedContainerTarget.querySelector(`input[value="${id}"]`)
    if (hiddenField) hiddenField.remove()
    
    // 取消选中对应的复选框
    const checkbox = document.getElementById(`project_select_${id}`)
    if (checkbox) checkbox.checked = false
  }
} 