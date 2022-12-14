import { MatDialogModule } from '@angular/material/dialog';
import { NgModule } from '@angular/core';
import { FuseSharedModule } from '@fuse/shared.module';

import { NavbarComponent } from 'app/layout/components/navbar/navbar.component';
import { NavbarHorizontalStyle1Module } from 'app/layout/components/navbar/horizontal/style-1/style-1.module';

@NgModule({
    declarations: [
        NavbarComponent
    ],
    imports     : [
        FuseSharedModule,
        MatDialogModule,
        NavbarHorizontalStyle1Module,
    ],
    exports     : [
        NavbarComponent
    ]
})
export class NavbarModule
{
}
