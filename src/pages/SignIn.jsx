import React, { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { LogIn, Mail, Lock, Loader2, ArrowRight } from "lucide-react";
import { api, saveUserSession } from "../utils/api";
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "../components/ui/Card";
import { Input } from "../components/ui/Input";
import { Button } from "../components/ui/Button";

export default function SignIn() {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    email: "",
    password: ""
  });
  const [errors, setErrors] = useState({});
  const [isLoading, setIsLoading] = useState(false);
  const [apiError, setApiError] = useState("");

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    if (errors[name]) {
      setErrors((prev) => ({ ...prev, [name]: "" }));
    }
    setApiError("");
  };

  const validateForm = () => {
    const newErrors = {};
    if (!formData.email.trim()) {
      newErrors.email = "Email is required";
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = "Invalid email address";
    }

    if (!formData.password) {
      newErrors.password = "Password is required";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    setIsLoading(true);
    setApiError("");

    try {
      const response = await api.signin(formData);
      saveUserSession(response.user, response.token);
      navigate("/");
    } catch (err) {
      setApiError(err.message || "Invalid email or password.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen w-full flex items-center justify-center p-4 relative bg-[#0b0f19] overflow-hidden">
      {/* Background ambient glow bubbles */}
      <div className="absolute top-[-10%] right-[-10%] w-[50%] h-[50%] bg-indigo-500/10 rounded-full blur-[120px] animate-pulse-glow" />
      <div className="absolute bottom-[-10%] left-[-10%] w-[50%] h-[50%] bg-purple-500/10 rounded-full blur-[120px] animate-pulse-glow" style={{ animationDelay: "-5s" }} />

      <Card className="w-full max-w-md z-10">
        <CardHeader className="text-center">
          <div className="mx-auto bg-gradient-to-tr from-indigo-500 to-purple-500 p-3 rounded-2xl w-fit text-white mb-3 shadow-lg shadow-indigo-500/15">
            <LogIn size={28} />
          </div>
          <CardTitle className="text-3xl font-extrabold bg-gradient-to-r from-white via-indigo-100 to-indigo-300 bg-clip-text text-transparent">
            Welcome Back
          </CardTitle>
          <CardDescription className="text-gray-400 mt-1.5">
            Sign in to your account to manage registrations and setup events.
          </CardDescription>
        </CardHeader>

        <CardContent>
          <form onSubmit={handleSubmit} noValidate className="space-y-5">
            {apiError && (
              <div className="p-3 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400 text-sm text-center font-medium">
                {apiError}
              </div>
            )}

            <Input
              label="Email Address"
              name="email"
              type="email"
              placeholder="john@example.com"
              value={formData.email}
              onChange={handleChange}
              error={errors.email}
              className="pl-3"
            />

            <div className="space-y-1">
              <Input
                label="Password"
                name="password"
                type="password"
                placeholder="••••••••"
                value={formData.password}
                onChange={handleChange}
                error={errors.password}
                className="pl-3"
              />
              <div className="text-right">
                <span className="text-xs text-gray-500 hover:text-indigo-400 cursor-pointer transition-colors duration-150">
                  Forgot password? (Demo)
                </span>
              </div>
            </div>

            <Button
              type="submit"
              disabled={isLoading}
              className="w-full mt-2 py-2.5 font-semibold text-white flex items-center justify-center gap-2"
            >
              {isLoading ? (
                <>
                  <Loader2 size={18} className="animate-spin" />
                  Signing In...
                </>
              ) : (
                <>
                  Sign In
                  <ArrowRight size={16} />
                </>
              )}
            </Button>
          </form>
        </CardContent>

        <CardFooter className="justify-center border-t border-white/5 pt-4 text-sm text-gray-400">
          Don't have an account?{" "}
          <Link to="/signup" className="text-indigo-400 hover:text-indigo-300 font-semibold ml-1.5 transition-colors duration-150">
            Sign Up
          </Link>
        </CardFooter>
      </Card>
    </div>
  );
}
