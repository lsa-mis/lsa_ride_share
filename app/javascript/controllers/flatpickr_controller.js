import { Application } from '@hotwired/stimulus'
import Flatpickr from 'stimulus-flatpickr'

const application = Application.start()
application.register('flatpickr', Flatpickr)
