import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

import { ScannerComponent } from './scanner/scanner.component';

const routes: Routes = [
  { path: 'scanner', component: ScannerComponent },
  { path: '', redirectTo: 'scanner', pathMatch: 'full' }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
