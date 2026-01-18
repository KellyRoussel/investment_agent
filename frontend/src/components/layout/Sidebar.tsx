import { NavLink } from 'react-router-dom';
import {
  ChartBarIcon,
  BriefcaseIcon,
  UserCircleIcon,
  ArrowRightOnRectangleIcon,
} from '@heroicons/react/24/outline';
import { useAuth } from '@hooks/useAuth';

interface NavItem {
  name: string;
  path: string;
  icon: React.ComponentType<React.SVGProps<SVGSVGElement>>;
}

const navItems: NavItem[] = [
  { name: 'Portfolio', path: '/portfolio', icon: ChartBarIcon },
  { name: 'Investments', path: '/investments', icon: BriefcaseIcon },
  { name: 'Profile', path: '/profile', icon: UserCircleIcon },
];

export function Sidebar() {
  const { user, logout } = useAuth();

  return (
    <div className="fixed left-0 top-0 h-screen w-64 bg-[#151932] border-r border-[#1f2544] flex flex-col">
      {/* Logo/Brand */}
      <div className="p-6 border-b border-[#1f2544]">
        <h1 className="text-2xl font-bold bg-gradient-to-r from-[#22d3ee] to-[#a78bfa] bg-clip-text text-transparent">
          InvestTrack
        </h1>
        {user && (
          <p className="text-sm text-gray-400 mt-2 truncate">{user.email}</p>
        )}
      </div>

      {/* Navigation */}
      <nav className="flex-1 p-4 space-y-2">
        {navItems.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            className={({ isActive }) =>
              `flex items-center gap-3 px-4 py-3 rounded-lg transition-all duration-200 ${
                isActive
                  ? 'bg-[#22d3ee]/10 text-[#22d3ee] shadow-lg shadow-[#22d3ee]/20'
                  : 'text-gray-400 hover:bg-[#252b4a] hover:text-gray-200'
              }`
            }
          >
            {({ isActive }) => (
              <>
                <item.icon
                  className={`w-5 h-5 ${isActive ? 'text-[#22d3ee]' : ''}`}
                />
                <span className="font-medium">{item.name}</span>
              </>
            )}
          </NavLink>
        ))}
      </nav>

      {/* Logout Button */}
      <div className="p-4 border-t border-[#1f2544]">
        <button
          onClick={logout}
          className="flex items-center gap-3 w-full px-4 py-3 rounded-lg text-gray-400 hover:bg-[#ef4444]/10 hover:text-[#ef4444] transition-all duration-200"
        >
          <ArrowRightOnRectangleIcon className="w-5 h-5" />
          <span className="font-medium">Logout</span>
        </button>
      </div>
    </div>
  );
}
