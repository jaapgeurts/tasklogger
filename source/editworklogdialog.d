module editworklogdialog;

import std.stdio;


import core.stdcpp.new_;
import qt.core.object;
import qt.core.string;
import qt.core.variant;
import qt.helpers;

import qt.widgets.ui;
import qt.widgets.dialog;
import qt.widgets.widget;
import qt.widgets.label;

import qt.widgets.pushbutton;

import worklogmodel;


class EditWorkLogDialog : QDialog {

    mixin(Q_OBJECT_D);

    this(QWidget parent = null) {

        super(parent);

        this.ui = cpp_new!(typeof(*ui));

        ui.setupUi(this);

    }

    ~this() {
        cpp_delete(ui);
    }

    void setWorkLogItem(WorkLog item) {
        ui.leTitle.setText(QString(item.title));
    }

private:
    UIStruct!"editworklogdialog.ui"* ui;

}
