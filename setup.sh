#!/bin/bash
# STUDENT TASK MANAGER - AUTOMATED SETUP SCRIPT
# This script sets up everything you need in ~2 minutes

set -e

echo "🚀 Student Task Manager - Setup Script"
echo "======================================"
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js from https://nodejs.org"
    exit 1
fi

echo "✅ Node.js found: $(node --version)"
echo ""

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm not found. Please install Node.js"
    exit 1
fi

echo "✅ npm found: $(npm --version)"
echo ""

# Create project directory
PROJECT_DIR="task-manager"
if [ -d "$PROJECT_DIR" ]; then
    echo "⚠️  Directory '$PROJECT_DIR' already exists"
    read -p "Overwrite? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted"
        exit 1
    fi
    rm -rf "$PROJECT_DIR"
fi

echo "📁 Creating project directory..."
mkdir "$PROJECT_DIR"
cd "$PROJECT_DIR"

echo "📦 Creating Vite React project..."
npm create vite@latest . -- --template react --quiet

echo "📚 Installing dependencies..."
npm install --silent
npm install -D tailwindcss postcss autoprefixer --silent

echo "⚙️  Configuring Tailwind..."
npx tailwindcss init -p --quiet

# Create tailwind.config.js
cat > tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,jsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF

# Create/update index.css with Tailwind directives
cat > src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
    monospace;
}
EOF

# Replace App.jsx with task manager component
cat > src/App.jsx << 'EOFAPP'
import React, { useState, useMemo, useEffect } from 'react';
import { Trash2, Plus, Filter, SortAsc, CheckCircle2, Circle } from 'lucide-react';

export default function TaskManager() {
  const [tasks, setTasks] = useState(() => {
    const saved = localStorage.getItem('tasks');
    return saved ? JSON.parse(saved) : [
      { id: 1, title: 'Complete Discrete Math assignment', course: 'Discrete Math', dueDate: '2026-06-25', priority: 'high', completed: false },
      { id: 2, title: 'Study for Algorithms exam', course: 'Algorithms', dueDate: '2026-06-28', priority: 'high', completed: false },
      { id: 3, title: 'Read Chapter 5', course: 'Data Structures', dueDate: '2026-06-26', priority: 'medium', completed: true },
      { id: 4, title: 'Group project presentation', course: 'Low-Code Development', dueDate: '2026-06-30', priority: 'high', completed: false },
      { id: 5, title: 'Submit lab report', course: 'Computational Thinking', dueDate: '2026-06-27', priority: 'medium', completed: false },
    ];
  });

  const [courses, setCourses] = useState(() => {
    const saved = localStorage.getItem('courses');
    return saved ? JSON.parse(saved) : ['Discrete Math', 'Algorithms', 'Data Structures', 'Low-Code Development', 'Computational Thinking'];
  });

  const [showForm, setShowForm] = useState(false);
  const [filterCourse, setFilterCourse] = useState('all');
  const [filterPriority, setFilterPriority] = useState('all');
  const [sortBy, setSortBy] = useState('dueDate');
  
  const [formData, setFormData] = useState({
    title: '',
    course: courses[0] || '',
    dueDate: '',
    priority: 'medium',
    completed: false
  });

  useEffect(() => {
    localStorage.setItem('tasks', JSON.stringify(tasks));
  }, [tasks]);

  useEffect(() => {
    localStorage.setItem('courses', JSON.stringify(courses));
  }, [courses]);

  const filteredAndSortedTasks = useMemo(() => {
    let result = tasks;

    if (filterCourse !== 'all') {
      result = result.filter(task => task.course === filterCourse);
    }

    if (filterPriority !== 'all') {
      result = result.filter(task => task.priority === filterPriority);
    }

    result.sort((a, b) => {
      if (sortBy === 'dueDate') {
        return new Date(a.dueDate) - new Date(b.dueDate);
      } else if (sortBy === 'priority') {
        const priorityOrder = { high: 0, medium: 1, low: 2 };
        return priorityOrder[a.priority] - priorityOrder[b.priority];
      } else if (sortBy === 'course') {
        return a.course.localeCompare(b.course);
      } else if (sortBy === 'completion') {
        return a.completed === b.completed ? 0 : a.completed ? 1 : -1;
      }
      return 0;
    });

    return result;
  }, [tasks, filterCourse, filterPriority, sortBy]);

  const stats = useMemo(() => {
    const total = tasks.length;
    const completed = tasks.filter(t => t.completed).length;
    const urgentPending = tasks.filter(t => !t.completed && t.priority === 'high').length;
    const daysUntilDueDate = (dateStr) => {
      const today = new Date();
      const dueDate = new Date(dateStr);
      return Math.ceil((dueDate - today) / (1000 * 60 * 60 * 24));
    };
    const overdue = tasks.filter(t => !t.completed && daysUntilDueDate(t.dueDate) < 0).length;

    return { total, completed, urgentPending, overdue, completionRate: Math.round((completed / total) * 100) };
  }, [tasks]);

  const addTask = (e) => {
    e.preventDefault();
    if (!formData.title.trim() || !formData.dueDate) {
      alert('Please fill in title and due date');
      return;
    }

    const newTask = {
      id: Date.now(),
      ...formData,
      title: formData.title.trim()
    };

    setTasks([...tasks, newTask]);
    setFormData({ title: '', course: courses[0] || '', dueDate: '', priority: 'medium', completed: false });
    setShowForm(false);
  };

  const toggleComplete = (id) => {
    setTasks(tasks.map(task => task.id === id ? { ...task, completed: !task.completed } : task));
  };

  const deleteTask = (id) => {
    setTasks(tasks.filter(task => task.id !== id));
  };

  const addCourse = () => {
    const courseName = prompt('Enter course name:');
    if (courseName && !courses.includes(courseName)) {
      setCourses([...courses, courseName]);
      setFormData({ ...formData, course: courseName });
    }
  };

  const formatDate = (dateStr) => {
    const date = new Date(dateStr);
    const today = new Date();
    const daysUntil = Math.ceil((date - today) / (1000 * 60 * 60 * 24));
    
    if (daysUntil < 0) return `Overdue by ${Math.abs(daysUntil)} days`;
    if (daysUntil === 0) return 'Today';
    if (daysUntil === 1) return 'Tomorrow';
    return `${daysUntil} days left`;
  };

  const getPriorityColor = (priority) => {
    switch (priority) {
      case 'high': return 'bg-red-100 text-red-800 border-red-300';
      case 'medium': return 'bg-yellow-100 text-yellow-800 border-yellow-300';
      case 'low': return 'bg-green-100 text-green-800 border-green-300';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 p-8">
      <div className="max-w-6xl mx-auto">
        <div className="bg-white rounded-lg shadow-lg p-8 mb-8">
          <h1 className="text-4xl font-bold text-gray-800 mb-2">Student Task Manager</h1>
          <p className="text-gray-600 mb-6">Organize assignments by priority, course, and deadline</p>
          
          <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
            <div className="bg-blue-50 rounded-lg p-4 border-l-4 border-blue-500">
              <p className="text-sm text-gray-600">Total Tasks</p>
              <p className="text-2xl font-bold text-blue-600">{stats.total}</p>
            </div>
            <div className="bg-green-50 rounded-lg p-4 border-l-4 border-green-500">
              <p className="text-sm text-gray-600">Completed</p>
              <p className="text-2xl font-bold text-green-600">{stats.completed}</p>
            </div>
            <div className="bg-red-50 rounded-lg p-4 border-l-4 border-red-500">
              <p className="text-sm text-gray-600">Urgent</p>
              <p className="text-2xl font-bold text-red-600">{stats.urgentPending}</p>
            </div>
            <div className="bg-orange-50 rounded-lg p-4 border-l-4 border-orange-500">
              <p className="text-sm text-gray-600">Overdue</p>
              <p className="text-2xl font-bold text-orange-600">{stats.overdue}</p>
            </div>
            <div className="bg-purple-50 rounded-lg p-4 border-l-4 border-purple-500">
              <p className="text-sm text-gray-600">Progress</p>
              <p className="text-2xl font-bold text-purple-600">{stats.completionRate}%</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-lg p-6 mb-8">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                <Filter className="inline mr-2" size={16} /> Filter by Course
              </label>
              <select value={filterCourse} onChange={(e) => setFilterCourse(e.target.value)} className="w-full px-4 py-2 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none">
                <option value="all">All Courses</option>
                {courses.map(course => (<option key={course} value={course}>{course}</option>))}
              </select>
            </div>

            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">Filter by Priority</label>
              <select value={filterPriority} onChange={(e) => setFilterPriority(e.target.value)} className="w-full px-4 py-2 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none">
                <option value="all">All Priorities</option>
                <option value="high">High Priority</option>
                <option value="medium">Medium Priority</option>
                <option value="low">Low Priority</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                <SortAsc className="inline mr-2" size={16} /> Sort by
              </label>
              <select value={sortBy} onChange={(e) => setSortBy(e.target.value)} className="w-full px-4 py-2 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none">
                <option value="dueDate">Due Date</option>
                <option value="priority">Priority</option>
                <option value="course">Course</option>
                <option value="completion">Completion Status</option>
              </select>
            </div>

            <div className="flex items-end">
              <button onClick={() => setShowForm(!showForm)} className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-lg flex items-center justify-center gap-2 transition">
                <Plus size={20} /> Add Task
              </button>
            </div>
          </div>

          {showForm && (
            <form onSubmit={addTask} className="bg-gray-50 p-6 rounded-lg border-2 border-blue-200">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                <input type="text" placeholder="Task title" value={formData.title} onChange={(e) => setFormData({ ...formData, title: e.target.value })} className="px-4 py-2 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none" />
                <input type="date" value={formData.dueDate} onChange={(e) => setFormData({ ...formData, dueDate: e.target.value })} className="px-4 py-2 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none" />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                <select value={formData.course} onChange={(e) => setFormData({ ...formData, course: e.target.value })} className="px-4 py-2 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none">
                  {courses.map(course => (<option key={course} value={course}>{course}</option>))}
                </select>

                <select value={formData.priority} onChange={(e) => setFormData({ ...formData, priority: e.target.value })} className="px-4 py-2 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none">
                  <option value="low">Low Priority</option>
                  <option value="medium">Medium Priority</option>
                  <option value="high">High Priority</option>
                </select>

                <button type="button" onClick={addCourse} className="bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded-lg transition">
                  + New Course
                </button>
              </div>

              <div className="flex gap-3">
                <button type="submit" className="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-6 rounded-lg transition">
                  Save Task
                </button>
                <button type="button" onClick={() => setShowForm(false)} className="bg-gray-400 hover:bg-gray-500 text-white font-bold py-2 px-6 rounded-lg transition">
                  Cancel
                </button>
              </div>
            </form>
          )}
        </div>

        <div className="space-y-4">
          {filteredAndSortedTasks.length === 0 ? (
            <div className="bg-white rounded-lg shadow-lg p-12 text-center">
              <p className="text-gray-500 text-lg">No tasks match your filters. Great job!</p>
            </div>
          ) : (
            filteredAndSortedTasks.map(task => (
              <div key={task.id} className={`bg-white rounded-lg shadow-md p-6 transition transform hover:shadow-lg flex items-center gap-4 ${task.completed ? 'opacity-75' : ''}`}>
                <button onClick={() => toggleComplete(task.id)} className="flex-shrink-0 text-blue-600 hover:text-blue-800 transition">
                  {task.completed ? (
                    <CheckCircle2 size={24} className="text-green-600" />
                  ) : (
                    <Circle size={24} />
                  )}
                </button>

                <div className="flex-grow">
                  <h3 className={`text-lg font-semibold ${task.completed ? 'line-through text-gray-500' : 'text-gray-800'}`}>
                    {task.title}
                  </h3>
                  <div className="flex flex-wrap gap-3 mt-2">
                    <span className="text-sm text-gray-600 font-medium">{task.course}</span>
                    <span className={`text-xs px-3 py-1 rounded-full border ${getPriorityColor(task.priority)}`}>
                      {task.priority.toUpperCase()} PRIORITY
                    </span>
                    <span className="text-sm text-gray-600">
                      📅 {formatDate(task.dueDate)}
                    </span>
                  </div>
                </div>

                <button onClick={() => deleteTask(task.id)} className="flex-shrink-0 text-red-500 hover:text-red-700 transition">
                  <Trash2 size={20} />
                </button>
              </div>
            ))
          )}
        </div>

        <div className="mt-12 text-center text-gray-600 text-sm">
          <p>All data is saved locally in your browser. Your tasks persist across sessions.</p>
        </div>
      </div>
    </div>
  );
}
EOFAPP

echo "✅ Installing lucide-react icons..."
npm install lucide-react --silent

echo ""
echo "✨ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "  1. Run locally: npm run dev"
echo "  2. To deploy to Vercel:"
echo "     - Push to GitHub"
echo "     - Visit https://vercel.com/new"
echo "     - Import your GitHub repository"
echo "     - Click Deploy"
echo ""
echo "🚀 Your app will be live at: https://your-project.vercel.app"
echo ""
echo "📱 To test: npm run dev, then open http://localhost:5173"
echo ""
echo "Good luck with your presentation! 🎉"
