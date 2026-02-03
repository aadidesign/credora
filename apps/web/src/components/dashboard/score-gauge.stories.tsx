import type { Meta, StoryObj } from "@storybook/react";
import { ScoreGauge } from "./score-gauge";

const meta: Meta<typeof ScoreGauge> = {
  title: "Dashboard/ScoreGauge",
  component: ScoreGauge,
  tags: ["autodocs"],
  argTypes: {
    score: { control: { type: "range", min: 0, max: 1000 } },
    size: { control: { type: "number", min: 80, max: 400 } },
  },
};

export default meta;

type Story = StoryObj<typeof ScoreGauge>;

export const Default: Story = {
  args: {
    score: 650,
    size: 180,
  },
};

export const Newcomer: Story = {
  args: { score: 150, size: 180 },
};

export const Prime: Story = {
  args: { score: 850, size: 180 },
};
