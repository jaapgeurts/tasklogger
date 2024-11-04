module taskmodel;

import std.stdio;
import std.typecons;
import std.algorithm.searching;
import std.algorithm.iteration;
import std.conv;
import std.array;

import qt.helpers;
import qt.core.namespace;
import qt.core.abstractitemmodel;
import qt.core.string;
import qt.core.variant;

import d2sqlite3;

import common;
import worklogmodel;

class Task {

    this() {
        this.id = -1;
    } // required for registertype

    this(uint parentId) {
        this.id = -1;
        this.parentId = parentId;
    }

    this(string description) {
        this(-1, description, Nullable!uint.init);
    }

    this(uint id, string description, Nullable!uint parentId) {
        this.id = id;
        this.description = description;
        this.parentId = parentId;
    }

    uint id;
    Nullable!uint parentId;
    string description;

    uint minutes;

    private Task parent;
    private Task[] children;

}

class TaskModel : QAbstractItemModel {

public:

    this(Database db) {
        this.db = db;

        loadData();

    }

    ~this() {
    }

    public void addTask(Task parent, Task task) {

        beginResetModel();
        // add the task to the database
        db.execute("INSERT INTO Task (Description, ParentId) VALUES (:description, :parentid);", task.description, parent
                .id);

        task.parentId = parent.id;
        task.id = db.lastInsertRowid.to!uint;
        // update the model
        parent.children ~= task;

        endResetModel();
    }

    private void loadData() {

        auto count = db.execute("SELECT count(*) FROM Task;").oneValue!uint;
        Task[] content = new Task[count];

        auto results = db.execute("SELECT Id, Description, ParentId FROM Task ORDER BY ParentId, Description;");

        // store copy in local array first
        int i = 0;
        foreach (Row row; results) {
            writeln("Adding task");
            // store in 

            Task task = new Task(row["Id"].as!uint, row["Description"].as!string, row["ParentId"].as!(
                    Nullable!uint));
            content[i] = task;

            if (task.parentId.isNull) {
                roots ~= task;
            }

            i++;
        }

        void buildTree(Task node) {
            node.children = content
                .filter!(e => e.parentId == node.id)
                .map!((e){
                    e.parent = node;
                    buildTree(e);
                    return e;
                })
                .array;
    
            // FIXME: dependency issue with accessing worklog model data
            uint count = db.execute("SELECT SUM(Minutes) FROM WorkLog WHERE taskId = :taskId;", node.id).oneValue!uint;

            node.minutes = count + node.children.fold!((uint a,Task b) => a + b.minutes)(0);
        }

        roots.each!buildTree;
    }

    extern (C++) override int columnCount(ref const(QModelIndex) parent = globalInitVar!QModelIndex) const {
        return 2;
    }

    // return the number of children that the parent has
    extern (C++) override int rowCount(ref const(QModelIndex) parent = globalInitVar!QModelIndex) const {

        if (!parent.isValid())
            return roots.length.to!int;

        // Check if this item has children
        if (parent.internalPointer is null)
            return 0;

        // else
        return (cast(Task) parent.internalPointer).children.length.to!int;
    }

    extern (C++) override QVariant data(ref const(QModelIndex) index, int role = qt
            .core.namespace.ItemDataRole.DisplayRole) const {
        if (!index.isValid())
            return QVariant();

        if (role != qt.core.namespace.ItemDataRole.DisplayRole)
            return QVariant();

        Task task = cast(Task) index.internalPointer;

        switch (index.column()) {
            case 0:
                return QVariant(QString(task.description));
            case 1:
                return QVariant(QString(task.minutes.toHoursMinutes));
            default:
                return QVariant(QString("NOT IMPLEMENTED"));
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

        if (!hasIndex(row, column, parent))
            return QModelIndex();

        if (!parent.isValid()) {
            // This is a root item
            return createIndex(row, column, cast(void*)roots[row]);
        }

        Task task = cast(Task) parent.internalPointer;

        return createIndex(row, column, cast(void*)task.children[row]);

    }

    extern (C++) override QModelIndex parent(ref const(QModelIndex) index) const {

        if (!index.isValid())
            return QModelIndex();

        Task task = cast(Task)index.internalPointer;

        if (task.parent is null)
            return QModelIndex();

        // find the position of this item in the children list of the parent task
        int row = task.parent.children.countUntil!(e => e.id == task.id).to!int;

        return createIndex(row, 0, cast(void*)task.parent);
    }

    extern (C++) override QVariant headerData(int section, qt.core.namespace.Orientation orientation, int role) const {
        if (orientation == qt.core.namespace.Orientation.Horizontal && role == qt
            .core.namespace.ItemDataRole.DisplayRole) {
            if (section == 0)
                return QVariant(QString("Name"));
            if (section == 1)
                return QVariant(QString("Hours"));
        }

        // if (orientation == qt.core.namespace.Orientation.Vertical && role == qt.core.namespace.ItemDataRole.DisplayRole)
        // {
        //     return QVariant(QString.number(section + 1));
        // }

        return QVariant();
    }

private:
    Task[] roots;
    Database db;
}
