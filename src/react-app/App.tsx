import { Routes, Route } from "react-router-dom";
import Header from "./components/Header";
import Footer from "./components/Footer";
import Home from "./pages/Home";
import AppDetail from "./pages/AppDetail";
import Admin from "./pages/Admin";
import { useMe } from "./lib/useMe";

export default function App() {
  const { me, loading, logout } = useMe();

  return (
    <>
      <Header me={me} logout={logout} />
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/apps/:slug" element={<AppDetail />} />
        <Route path="/admin" element={<Admin me={me} meLoading={loading} />} />
      </Routes>
      <Footer />
    </>
  );
}
