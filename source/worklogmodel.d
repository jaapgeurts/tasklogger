module worklogmodel;

import std.stdio;
import std.conv;
import std.format;
import std.algorithm.searching;

import qt.helpers;
import qt.core.namespace;
import qt.core.abstractitemmodel;
import qt.core.string;
import qt.core.variant;

import d2sqlite3;



class WorkLog {

    this() {
        this.id = -1;
    } // required for registertype

    this(uint id, uint taskId, string title, uint minutes, string date) {
        this.id = id;
        this.taskId = taskId;

        this.title = title;
        this.minutes = minutes;
        this.date = date;
    }

    uint id;
    uint taskId;
    string title;
    uint minutes;
    string date;

}

class WorkLogModel : QAbstractItemModel {

    this(Database db) {
        this.db = db;

        //content = [QString("John"),QString("Mary"),QString("Susan"),QString("Peter"),QString("William")];
        headerNames = [QString("Title"), QString("Time"), QString("Date")];
    }

    ~this() {
    }

    public void setTask(uint taskId) {
        beginResetModel();
        fetchData(taskId);
        endResetModel();
    } 

    public WorkLog at(int index) {
        return content[index];
    }

    public void updateWorkLog(WorkLog workLog) {
        beginResetModel();
        writeln("Updating worklog: ", workLog.id);
        Statement stmt = db.prepare("UPDATE WorkLog SET Title = :title, Minutes = :minutes, Date = :date, TaskId = :taskid WHERE Id = :id;");
        stmt.bind(":id", workLog.id);
        stmt.bind(":taskid", workLog.taskId);
        stmt.bind(":title", workLog.title);
        stmt.bind(":minutes", workLog.minutes);
        stmt.bind(":date", workLog.date);
        stmt.execute();

        writeln("Changes made: ", db.changes);
        writeln("Error: ", db.errorCode);

        WorkLog item = content.find!(e => e.id == workLog.id)[0];
        item.title = workLog.title;
        item.minutes = workLog.minutes;
        item.date = workLog.date;
        item.taskId = workLog.taskId;
        endResetModel();
    }

    public void addWorkLog(WorkLog workLog, uint taskId) {
        beginResetModel();
        writeln("Adding worklog");
        db.execute("INSERT INTO WorkLog (Title, Minutes, Date, TaskId) VALUES (:title, :minutes, :date, :taskid);",
            workLog.title, workLog.minutes, workLog.date, taskId);

        writeln("Changes made: ", db.changes);
        writeln("Error: ", db.errorCode);

        workLog.id = db.lastInsertRowid.to!uint;
        workLog.title = workLog.title;
        workLog.minutes = workLog.minutes;
        workLog.date = workLog.date;
        workLog.taskId = taskId;
        content ~= workLog;

        endResetModel();
    }

    private void fetchData(uint taskId) {

        uint count = db.execute("SELECT count(*) FROM WorkLog WHERE taskId = :taskId;", taskId).oneValue!uint;
        content = new WorkLog[count];

        auto results = db.execute(
            "SELECT Id, Title, Minutes, TaskId, Date FROM WorkLog WHERE taskId = :taskId;", taskId);
        int i = 0;
        foreach (Row row; results) {
            writeln("Adding worklog");

            content[i] = new WorkLog(row["Id"].as!uint, row["TaskId"].as!uint,
                row["Title"].as!string, row["Minutes"].as!uint, row["Date"].as!string);
            i++;
        }
    }

    extern (C++) override int columnCount(ref const(QModelIndex) parent = globalInitVar!QModelIndex) const {
        return 3;
    }

    extern (C++) override int rowCount(ref const(QModelIndex) parent = globalInitVar!QModelIndex) const {
        return content.length.to!int;
    }

    extern (C++) override QVariant data(ref const(QModelIndex) index, int role = qt
            .core.namespace.ItemDataRole.DisplayRole) const {
        if (!index.isValid())
            return QVariant();

        if (role != qt.core.namespace.ItemDataRole.DisplayRole)
            return QVariant();


        final switch(index.column) {
            case 0:
                return QVariant(QString(content[index.row()].title));
            case 1:
                int minutes = content[index.row()].minutes;
                // TODO: convert minutes to days, hours and minutes and return as string
                // int days = minutes / (24 * 60);
                int hours = minutes / 60;
                minutes = minutes % 60;
                return QVariant(QString(format("%d:%02d", hours, minutes)));
            case 2:
                return QVariant(QString(content[index.row()].date));
        }
    }

    extern (C++) override qt.core.namespace.ItemFlags flags(ref const(QModelIndex) index) const {
        if (!index.isValid())
            return qt.core.namespace.ItemFlags.NoItemFlags;

        return QAbstractItemModel.flags(index) | qt.core.namespace.ItemFlag.ItemIsEditable;
    }

    extern (C++) override bool setData(ref const(QModelIndex) index, ref const(QVariant) value, int role) {
        // if (role != qt.core.namespace.ItemDataRole.EditRole)
        //     return false;

        // int[2] key = [index.column(), index.row()];
        // content[key] = value.toString();
        // QVector!(int) roles = QVector!(int).create();
        // roles.append(qt.core.namespace.ItemDataRole.DisplayRole);
        // roles.append(qt.core.namespace.ItemDataRole.EditRole);
        // /+ emit +/ dataChanged(index, index, roles);

        return false;
    }

    extern (C++) override QModelIndex index(int row, int column, ref const(QModelIndex) parent = globalInitVar!QModelIndex) const {
        if (parent.isValid())
            return QModelIndex();

        return createIndex(row, column, null);
    }

    extern (C++) override QModelIndex parent(ref const(QModelIndex) index) const {
        return QModelIndex();
    }

    extern (C++) override QVariant headerData(int section, qt.core.namespace.Orientation orientation, int role) const {
        if (orientation == qt.core.namespace.Orientation.Horizontal && role == qt
            .core.namespace.ItemDataRole.DisplayRole) {
                return QVariant(headerNames[section]);
        }

        // if (orientation == qt.core.namespace.Orientation.Vertical && role == qt.core.namespace.ItemDataRole.DisplayRole)
        // {
        //     return QVariant(QString.number(section + 1));
        // }

        return QVariant();
    }

private:
    WorkLog[] content;
    Database db;

    QString[] headerNames;

}
