import { Routes, Route } from "react-router-dom";
import Header from "./components/Header";
import Footer from "./components/Footer";
import Home from "./pages/Home";
import AppDetail from "./pages/AppDetail";
import Admin from "./pages/Admin";
import Contact from "./pages/Contact";
import ContactDetail from "./pages/ContactDetail";
import Privacy from "./pages/Privacy";
import { useMe } from "./lib/useMe";

export default function App() {
  const { me, loading, logout } = useMe();

  return (
    <>
      <Header me={me} logout={logout} />
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/apps/:slug" element={<AppDetail me={me} />} />
        <Route path="/apps/:slug/privacy" element={<Privacy me={me} />} />
        <Route path="/contact" element={<Contact me={me} />} />
        <Route path="/contact/:id" element={<ContactDetail me={me} />} />
        <Route path="/admin" element={<Admin me={me} meLoading={loading} />} />
      </Routes>
      <Footer />
    </>
  );
}
