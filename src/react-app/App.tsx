import { useEffect } from "react";
import { Routes, Route } from "react-router-dom";
import Header from "./components/Header";
import Footer from "./components/Footer";
import Home from "./pages/Home";
import AppDetail from "./pages/AppDetail";
import Admin from "./pages/Admin";
import Contact from "./pages/Contact";
import ContactDetail from "./pages/ContactDetail";
import Privacy from "./pages/Privacy";
import Crew from "./pages/Crew";
import CrewDetail from "./pages/CrewDetail";
import AppReview from "./pages/AppReview";
import AiEdu from "./pages/AiEdu";
import AiEduDetail from "./pages/AiEduDetail";
import TechDex from "./pages/TechDex";
import Login from "./pages/Login";
import { useMe } from "./lib/useMe";

// 페이지 로드당 1회만 방문 집계 (StrictMode 이중 실행 방지용 모듈 플래그)
let visitTracked = false;

export default function App() {
  const { me, loading, logout, refresh } = useMe();

  useEffect(() => {
    if (visitTracked) return;
    visitTracked = true;
    void fetch("/api/visits/track", { method: "POST" }).catch(() => {});
  }, []);

  return (
    <>
      <Header me={me} logout={logout} />
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/login" element={<Login me={me} refresh={refresh} />} />
        <Route path="/apps/:slug" element={<AppDetail me={me} />} />
        <Route path="/apps/:slug/privacy" element={<Privacy me={me} />} />
        <Route path="/contact" element={<Contact me={me} />} />
        <Route path="/contact/:id" element={<ContactDetail me={me} />} />
        <Route path="/crew" element={<Crew me={me} meLoading={loading} />} />
        <Route path="/crew/:id" element={<CrewDetail me={me} />} />
        <Route path="/appreview" element={<AppReview me={me} meLoading={loading} />} />
        <Route path="/ai-edu" element={<AiEdu me={me} />} />
        <Route path="/ai-edu/:id" element={<AiEduDetail me={me} />} />
        <Route path="/techdex" element={<TechDex />} />
        <Route path="/admin" element={<Admin me={me} meLoading={loading} />} />
      </Routes>
      <Footer />
    </>
  );
}
